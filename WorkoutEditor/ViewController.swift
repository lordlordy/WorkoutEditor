//
//  ViewController.swift
//  WorkoutEditor
//
//  Created by Steven Lord on 30/08/2019.
//  Copyright © 2019 Steven Lord. All rights reserved.
//

// TO DO
// 1. Deleting of race results - need to remove from DB ---- DONE
// 2. Deleting of workouts - need to remove from DB ---- DONE
// 3. Report error when don't save - eg if input race with same date and raceNumber - this is a unique key so won't save
// 4. When change DB update RaceResults array

import Cocoa

class ViewController: NSViewController {

    @IBOutlet weak var progressBar: NSProgressIndicator!
    @IBOutlet weak var progressField: NSTextField!
    private var mainWindowName: String = ""
    private var selectedDataWarehouseURL: URL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "stevenlord.me.uk.SharedTrainingDiary")!.appendingPathComponent("DefaultDataWarehouse.sqlite3")
        
    var trainingDiary: TrainingDiary{
        return representedObject as! TrainingDiary
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let url = UserDefaults.standard.url(forKey: "DatabaseName"){
            WorkoutDBAccess.shared.setDBURL(toURL: url)
        }
        
        if let url = UserDefaults.standard.url(forKey: "DataWarehouseName"){
            selectedDataWarehouseURL = url
        }
        
        representedObject = WorkoutDBAccess.shared.createTrainingDiary()
        
        DataWarehouseGenerator(trainingDiary: trainingDiary, dbURL: selectedDataWarehouseURL).populateTrainingDiaryWithTSB()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        ValueTransformer.setValueTransformer(NumberToTimeFormatter(), forName: NSValueTransformerName(rawValue: "NumberToTimeFormatter"))
    }
    
    @IBAction func test(_ sender: Any){
        if let url = OpenAndSaveDialogues().selectedPath(withTitle: "chose .json file",andFileTypes: ["json"], directory: nil) {
            do{
                let data: Data = try Data.init(contentsOf: url)
                let jsonData  = try JSONSerialization.jsonObject(with: data, options: [.allowFragments, .mutableContainers])
                
                if let list = jsonData as? [[String: Any]]{
                    for l in list{
                        if let fields = l["fields"] as? [String:Any]{
                            let df: DateFormatter = DateFormatter()
                            df.dateFormat = "yyyy-MM-dd"
                            let date = df.date(from: fields["date"] as! String)!
                            let dc = Calendar.current.dateComponents([.day, .month, .year], from: date)
                            let raceDate: Date = Calendar.current.date(from: DateComponents(year: dc.year, month: dc.month!, day: dc.day, hour: 12, minute: 0, second: 0))!
                            let timeFormatter: NumberToTimeFormatter = NumberToTimeFormatter()
                            let rr:  RaceResult = RaceResult(date: raceDate,
                                                             raceNumber: 1,
                                                             type: fields["type"] as! String,
                                                             brand: fields["brand"] as! String,
                                                             distance: fields["distance"] as! String,
                                                             name: fields["name"] as! String,
                                                             category: fields["category"] as? String ?? "",
                                                             overallPosition: fields["overall_position"] as? Int ?? 0,
                                                             categoryPosition: fields["category_position"] as? Int ?? 0,
                                                             swimSeconds: Int(truncating: timeFormatter.reverseTransformedValue(fields["swim"]) as? NSNumber ?? 0),
                                                             t1Seconds: Int(truncating: timeFormatter.reverseTransformedValue(fields["t1"]) as? NSNumber ?? 0),
                                                             bikeSeconds: Int(truncating: timeFormatter.reverseTransformedValue(fields["bike"]) as? NSNumber ?? 0),
                                                             t2Seconds: Int(truncating: timeFormatter.reverseTransformedValue(fields["t2"]) as? NSNumber ?? 0),
                                                             runSeconds: Int(truncating: timeFormatter.reverseTransformedValue(fields["run"]) as? NSNumber ?? 0),
                                                             swimKM: fields["swim_km"] as? Double ?? 0.0,
                                                             bikeKM: fields["bike_km"] as? Double ?? 0.0,
                                                             runKM: fields["run_km"] as? Double ?? 0.0,
                                                             comments: fields["comments"] as! String,
                                                             raceReport: "")
                            WorkoutDBAccess.shared.save(raceResult: rr)
                            
                        }
                    }
                }
                
            } catch {
                print("Unable to retrieve contents of \(url)")
                print(error)
            }
        }
    }
    
    @IBAction func selectDatabase(_ sender: Any) {
        if let url = OpenAndSaveDialogues().selectedPath(withTitle: "select database",andFileTypes: ["sqlite3"], directory: FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "stevenlord.me.uk.SharedTrainingDiary")) {
            setDB(toURL: url)
            dbSwitch()
            updateWindowTitle()
        }
    }

    @IBAction func selectDataWarehouse(_ sender: Any) {
        if let url = OpenAndSaveDialogues().selectedPath(withTitle: "select data warehouse",andFileTypes: ["sqlite3"], directory: FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "stevenlord.me.uk.SharedTrainingDiary")) {
            selectedDataWarehouseURL = url
            UserDefaults.standard.set(url, forKey: "DataWarehouseName")
            updateWindowTitle()
        }
    }
    
    private func setDB(toURL url: URL){
        WorkoutDBAccess.shared.setDBURL(toURL: url)
        UserDefaults.standard.set(url, forKey: "DatabaseName")
    }
    
    private func updateWindowTitle(){
        if let w = view.window{
            w.title = "Database: \(WorkoutDBAccess.shared.dbName)  ~~  Warehouse: \(selectedDataWarehouseURL.lastPathComponent)"
            mainWindowName = w.title
        }
    }
    

    
    @IBAction func newDB(_ sender: Any){
        // let user select new DB
        if let url = OpenAndSaveDialogues().saveFilePath(suggestedFileName: "NewDB", allowFileTypes: ["sqlite3"], directory: FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "stevenlord.me.uk.SharedTrainingDiary")){
            WorkoutDBAccess.shared.createDatabase(atURL: url )
            setDB(toURL: url)
            dbSwitch()
            updateWindowTitle()
        }
    }
    
    @IBAction func newDataWarehouse(_ sender: Any){
        if let url = OpenAndSaveDialogues().saveFilePath(suggestedFileName: "NewDataWarehouse", allowFileTypes: ["sqlite3"], directory: FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "stevenlord.me.uk.SharedTrainingDiary")){
            selectedDataWarehouseURL = url
            UserDefaults.standard.set(url, forKey: "DataWarehouseName")
            DataWarehouseGenerator(trainingDiary: trainingDiary, dbURL: selectedDataWarehouseURL).createDB()
            updateWindowTitle()
        }
    }
    
    @IBAction func importJSON(_ sender: Any){
        if let url = OpenAndSaveDialogues().selectedPath(withTitle: "chose .json file",andFileTypes: ["json"], directory: nil) {
            let importer: JSONImporter = JSONImporter(progressUpdater: progressUpdater)
            progressBar.doubleValue = 0.0
            DispatchQueue.global(qos: .userInitiated).async {
                importer.importDiary(fromURL: url, intoTrainingDiary: self.trainingDiary)
                DispatchQueue.main.async {
                    self.dbSwitch()
                }
            }
        }
    }
    
    @IBAction func generateWarehouse(_ sender: Any){
        let msg = NSAlert()
        msg.addButton(withTitle: "Proceed")
        msg.addButton(withTitle: "Cancel")
        msg.messageText = "Rebuild Data Warehouse"
        msg.informativeText = "This will rebuild the Data Warehouse (\(selectedDataWarehouseURL.lastPathComponent)) from scratch and could take some time. Do you want to proceed?"
        
        if msg.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn{
            let generator = DataWarehouseGenerator(trainingDiary: trainingDiary, dbURL: selectedDataWarehouseURL)
            self.progressBar.doubleValue = 0.0
            DispatchQueue.global(qos: .userInitiated).async {
                generator.generate(progressUpdater: self.progressUpdater)
            }
        }
    }
    
    @IBAction func updateWarehouse(_ sender: Any){
        let generator = DataWarehouseGenerator(trainingDiary: trainingDiary, dbURL: selectedDataWarehouseURL)
        self.progressBar.doubleValue = 0.0
        DispatchQueue.global(qos: .userInitiated).async {
            generator.update(progressUpdater: self.progressUpdater)
        }
    }
    
    @IBAction func rebuildWarehouse(_ sender: Any){
        let latestDateStr = DataWarehouseGenerator(trainingDiary: trainingDiary, dbURL: selectedDataWarehouseURL).latestDateString()
        let msg = NSAlert()
        msg.addButton(withTitle: "Rebuild")
        msg.addButton(withTitle: "Cancel")
        msg.messageText = "Select date to rebuild from"
        msg.informativeText = "Warehouse data will be replaced on and after this date. Warehouse data to \(latestDateStr)"
        let dp = NSDatePicker(frame:NSRect(x:0, y:0, width: 125, height: 26))
        dp.datePickerElements = .yearMonthDay
        dp.dateValue = Date()
        msg.accessoryView = dp
        
        if msg.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn{
            let generator = DataWarehouseGenerator(trainingDiary: trainingDiary, dbURL: selectedDataWarehouseURL)
            self.progressBar.doubleValue = 0.0
            let fromDate: Date = dp.dateValue
            DispatchQueue.global(qos: .userInitiated).async {
                generator.rebuild(fromDate: fromDate, progressUpdater: self.progressUpdater)
            }
        }else{
            print("Rebuilding data warehouse from date cancelled")
        }
    }
    
    private func progressUpdater(percentage: Double, text: String) -> Void{
        DispatchQueue.main.async {
            self.progressBar.doubleValue = percentage * 100
            self.progressField.stringValue = text
        }
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        updateWindowTitle()
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        print(segue.sourceController)
        print(segue.destinationController)
    }

    
    private func dbSwitch(){
        
        // need to ditch all open editing windows as they reference a different DB. Then need to reload main window
        let options = CGWindowListOption(arrayLiteral: .excludeDesktopElements, .optionOnScreenOnly)
        let windowsListInfo = CGWindowListCopyWindowInfo(options, CGWindowID(0))
        let infoList = windowsListInfo as! [[String:Any]]
        let visibleWindows = infoList.filter{ $0["kCGWindowOwnerName"] as! String == "WorkoutEditor" }
        
        for v in visibleWindows{
            if v["kCGWindowName"] as! String != mainWindowName{
                // need to close this
                if let window = NSApp.window(withWindowNumber: v["kCGWindowNumber"] as! Int){
                    window.close()
                }
            }
        }
        
        representedObject = WorkoutDBAccess.shared.createTrainingDiary()
        
        for child in children{
            for c in child.children{
                if let yvc = c as? YearsViewController{
                    yvc.reloadOutlineView()
                }
            }
        }
        
    }

}


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
import CloudKit

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
    
    @IBAction func testFetch(_ sender: Any){
        let query: CKQuery = CKQuery(recordType: "Day", predicate: NSPredicate(value: true))
        CKContainer.default().privateCloudDatabase.perform(query, inZoneWith: nil) { (records, error) in
            if let e = error{
                print(e)
            }else if let recordArray = records{
                for r in recordArray{
                    print(r.lastModifiedUserRecordID)
                    print(r)
                }
            }
        }
    }
    
    @IBAction func test(_ sender: Any){
//       print("Test")
//        let containerIdentifier = "iCloud.uk.stevenlord.WorkoutEditor"
//        let container = CKContainer(identifier: containerIdentifier)
//        let targetDate: Date = Date()
//        let formatter: DateFormatter = DateFormatter()
//        formatter.dateFormat = "YYYY-MM-dd"
//        print(container)
//        let recordID = CKRecord.ID(recordName: formatter.string(from: targetDate), zoneID: CKRecordZone.default().zoneID)
//        let day: CKRecord = CKRecord(recordType: "Day", recordID: recordID)
//        let workout1: CKRecord = CKRecord(recordType: "Workout")
//        let workout2: CKRecord = CKRecord(recordType: "Workout")
//        day["date"] = targetDate
//        workout1["activity"] = "swim - i wish!"
//        workout1["day"] = CKRecord.Reference(: day.recordIDrecordID, action: .deleteSelf)
//        workout2["activity"] = "run"
//        workout2["day"] = CKRecord.Reference(recordID: day.recordID, action: .deleteSelf)
//
//
//        print(day)
//        print(workout1)
//        print(workout2)
//        container.privateCloudDatabase.save(workout1, completionHandler: ckCompletion)
//        container.privateCloudDatabase.save(workout2, completionHandler: ckCompletion)
//        container.privateCloudDatabase.save(day, completionHandler: ckCompletion)
        testSave()
    }
    
    func testSave(){
        let days: [Day] = trainingDiary.descendingOrderedDays(fromDate: nil)
        if days.count > 0{
            let targetDay: Day = days[0]
            let container = CKContainer(identifier: "iCloud.uk.stevenlord.WorkoutEditor")
            container.privateCloudDatabase.save(targetDay.asCKRecord(), completionHandler: ckCompletion)
            for reading in targetDay.readings{
                container.privateCloudDatabase.save(reading.asCKRecord(), completionHandler: ckCompletion)
            }
            for workout in targetDay.workouts{
                container.privateCloudDatabase.save(workout.asCKRecord(), completionHandler: ckCompletion)
            }
        }else{
            print("No days")
        }
    }
    
    func ckCompletion(record: CKRecord?, error: Error?){
        print(record?.modificationDate ?? "no record or date")
        print(record?.recordID ?? "no ID")
        print(record?.recordID.recordName ?? " no id")
        if let e = error{
            print(e)
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


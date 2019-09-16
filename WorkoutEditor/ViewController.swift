//
//  ViewController.swift
//  WorkoutEditor
//
//  Created by Steven Lord on 30/08/2019.
//  Copyright © 2019 Steven Lord. All rights reserved.
//

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

    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        ValueTransformer.setValueTransformer(NumberToTimeFormatter(), forName: NSValueTransformerName(rawValue: "NumberToTimeFormatter"))
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
        }
    }
    
    @IBAction func newDataWarehouse(_ sender: Any){
        if let url = OpenAndSaveDialogues().saveFilePath(suggestedFileName: "NewDataWarehouse", allowFileTypes: ["sqlite3"], directory: FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "stevenlord.me.uk.SharedTrainingDiary")){
            selectedDataWarehouseURL = url
            UserDefaults.standard.set(url, forKey: "DataWarehouseName")
            DataWarehouseGenerator(trainingDiary: trainingDiary, dbURL: selectedDataWarehouseURL).createDB()
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
        let generator = DataWarehouseGenerator(trainingDiary: trainingDiary, dbURL: selectedDataWarehouseURL)
        self.progressBar.doubleValue = 0.0
        DispatchQueue.global(qos: .userInitiated).async {
            generator.generate(progressUpdater: self.progressUpdater)
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
//                    yvc.representedObject = representedObject
                }
            }
        }
        
    }

}


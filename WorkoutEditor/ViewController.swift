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
    private var mainWindowName: String = ""
    
    var trainingDiary: TrainingDiary{
        return representedObject as! TrainingDiary
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let url = UserDefaults.standard.url(forKey: "DatabaseName"){
            print("setting url....")
            print(url)
            WorkoutDBAccess.shared.setDBURL(toURL: url)
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
        }
    }
    
    private func setDB(toURL url: URL){
        WorkoutDBAccess.shared.setDBURL(toURL: url)
        UserDefaults.standard.set(url, forKey: "DatabaseName")
        if let w = view.window{
            w.title = url.lastPathComponent
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
    
    @IBAction func importJSON(_ sender: Any){
        if let url = OpenAndSaveDialogues().selectedPath(withTitle: "chose .json file",andFileTypes: ["json"], directory: nil) {
            let importer: JSONImporter = JSONImporter(progressUpdater: progressUpdater)
            progressBar.doubleValue = 0.0
            DispatchQueue.global(qos: .userInitiated).async {
                importer.importDiary(fromURL: url, intoTrainingDiary: self.trainingDiary)
            }
        }
    }
    
    private func progressUpdater(percentage: Double) -> Void{
        DispatchQueue.main.async {
            self.progressBar.doubleValue = percentage * 100
        }
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        if let w = view.window{
            w.title = WorkoutDBAccess.shared.getDBURL().lastPathComponent
        }
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


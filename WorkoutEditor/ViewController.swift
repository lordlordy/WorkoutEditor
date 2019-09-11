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
        }
    }
    
    private func setDB(toURL url: URL){
        WorkoutDBAccess.shared.setDBURL(toURL: url)
        UserDefaults.standard.set(url, forKey: "DatabaseName")
        if let w = view.window{
            w.title = url.lastPathComponent
        }
    }
    

    
    @IBAction func newDB(_ sender: Any){
        if let url = OpenAndSaveDialogues().saveFilePath(suggestedFileName: "NewDB", allowFileTypes: ["sqlite3"], directory: FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "stevenlord.me.uk.SharedTrainingDiary")){
            WorkoutDBAccess.shared.createDatabase(atURL: url )
            setDB(toURL: url)
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

    @IBAction func openDocument(_ sender: Any){
        print("open document")
    }

}


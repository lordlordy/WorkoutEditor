//
//  ViewController.swift
//  WorkoutEditor
//
//  Created by Steven Lord on 30/08/2019.
//  Copyright © 2019 Steven Lord. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let url = UserDefaults.standard.url(forKey: "DatabaseName"){
            print("setting url....")
            print(url)
            WorkoutDBAccess.shared.dbURL = url
        }
        
        WorkoutDBAccess.shared.rebuildDBCache()
        
        // bit of testing
        let d1: Day = Day(date: Date(), type: "TEST", comments: "some comments")
        let d2: Day = Day(date: Calendar.current.date(from: DateComponents(year: 2019, month: 1, day: 1))!, type: "TEST", comments: "")
        WorkoutDBAccess.shared.save(day: d1)
        WorkoutDBAccess.shared.save(day: d2)
        
        WorkoutDBAccess.shared.save(reading: Reading(type: "fatigue", value: 2.0, parent: d1))
        WorkoutDBAccess.shared.save(reading: Reading(type: "motivation", value: 7.0, parent: d1))

        WorkoutDBAccess.shared.save(workout: Workout(day: d1, workout_number: 1, activity: "Test", activity_type: "Test", equipment: "None", seconds: 3600, rpe: 3.4, tss: 23.4, tss_method: "RPE", km: 12.3, kj: 1234, ascent_metres: 23, reps: 0, is_race: true, cadence: 23, watts: 234, watts_estimated: false, heart_rate: 124, is_brick: false, keywords: "", comments: "blag"))

    }

    
    
    @IBAction func selectDatabase(_ sender: Any) {
        if let url = OpenAndSaveDialogues().selectedPath(withTitle: "select database",andFileTypes: ["sqlite3"], directory: FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "stevenlord.me.uk.SharedTrainingDiary")) {
            
            WorkoutDBAccess.shared.dbURL = url
            UserDefaults.standard.set(url, forKey: "DatabaseName")
            if let w = view.window{
                w.title = url.lastPathComponent
            }
        }
    }
    
    @IBAction func newDB(_ sender: Any){
        if let url = OpenAndSaveDialogues().saveFilePath(suggestedFileName: "NewDB", allowFileTypes: ["sqlite3"], directory: FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "stevenlord.me.uk.SharedTrainingDiary")){
        
            WorkoutDBAccess.shared.createDatabase(atURL: url )
        }
    }
    
    @IBAction func importJSON(_ sender: Any){
        if let url = OpenAndSaveDialogues().selectedPath(withTitle: "chose .json file",andFileTypes: ["json"], directory: nil) {
            print(url)
            let importer: JSONImporter = JSONImporter()
            importer.importDiary(fromURL: url)
        }
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        if let w = view.window{
            w.title = WorkoutDBAccess.shared.dbURL.lastPathComponent
        }
    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func openDocument(_ sender: Any){
        print("open document")
    }

}


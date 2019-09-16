//
//  YearsViewController.swift
//  WorkoutEditor
//
//  Created by Steven Lord on 10/09/2019.
//  Copyright © 2019 Steven Lord. All rights reserved.
//

import Cocoa

class YearsViewController: NSViewController {

    @objc dynamic var nodes: [PeriodNode] = []
    @IBOutlet weak var toggleYearWeeksButton: NSButton!
    @IBOutlet weak var outlineView: NSOutlineView!
    @IBOutlet var years: NSTreeController!
    private var months: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        if let mainVC = parent?.parent as? ViewController{
            if let td = mainVC.representedObject as? TrainingDiary{
                nodes = [td]
            }
        }
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        outlineView.expandItem(outlineView.item(atRow: 0))
        outlineView.expandItem(outlineView.item(atRow: 1))
        outlineView.expandItem(outlineView.item(atRow: 2))
        outlineView.expandItem(outlineView.item(atRow: 3))
    }
    
    @IBAction func exportSelection(_ sender: Any) {
        if let url = OpenAndSaveDialogues().saveFilePath(suggestedFileName: "Days", allowFileTypes: ["json"], directory: nil){
            
            var days: Set<Day> = Set()
            if let periodNodes = years.selectedObjects as? [PeriodNode]{
                for pn in periodNodes{
                    days = days.union(pn.days)
                }
            }
            if let jsonString = JSONExporter().createJSON(forDays: Array(days)){
                do{
                    try jsonString.write(to: url, atomically: true, encoding: String.Encoding.utf8.rawValue)
                }catch{
                    print("Unable to save JSON")
                    print(error)
                }
            }
        }
    }
    
    @IBAction func reload(_ sender: Any) {
        if let td = trainingDiary{
            td.setNodesForRebuild()
        }
        reloadOutlineView()
    }
    
    var trainingDiary: TrainingDiary?{
        if let mainVC = parent?.parent as? ViewController{
            return mainVC.representedObject as? TrainingDiary
        }
        return nil
    }
    
    @IBAction func toggleYearWeeks(_ sender: NSButton) {
        toggleYearWeeksButton.title = months ? "Show Months" : "Show Weeks"
        months = !months
        if let td = trainingDiary{
            td.monthly = months
            reloadOutlineView()
        }
    }
    
    func reloadOutlineView(){
        if let td = trainingDiary{
            nodes = [td]
            outlineView.reloadData()
            outlineView.expandItem(outlineView.item(atRow: 0))
            outlineView.expandItem(outlineView.item(atRow: 1))
            outlineView.expandItem(outlineView.item(atRow: 2))
            outlineView.expandItem(outlineView.item(atRow: 3))
        }
    }
        
    @IBAction func newDay(_ sender: NSButton) {
        if let td = trainingDiary{
            let day: Day = td.defaultNewDay()
            openWindow(withDay: day)
        }
    }
    
    @IBAction func doubleClick(_ sender: NSOutlineView) {
        let item = sender.item(atRow: sender.clickedRow)
        if let n = item as? NSTreeNode{
            if let day = n.representedObject as? Day{
                openWindow(withDay: day)
            }else if let workout = n.representedObject as? Workout{
                openWindow(withDay: workout.day)
            }
        }
        
    }
    
    private func openWindow(withDay day: Day){
        let myWindowController = NSStoryboard(name: "Day", bundle: nil).instantiateController(withIdentifier: "DayWindowController") as! NSWindowController
        myWindowController.showWindow(self)
        let df: DateFormatter = DateFormatter()
        df.dateFormat = "EEEE dd-MMM-yyyy HH:mm:ss ZZ"
        myWindowController.window?.title = df.string(from: day.date)
        if let vc = myWindowController.contentViewController as? DayViewController{
            vc.mainViewController = parent?.parent as? ViewController
            vc.representedObject = day
            vc.readingsAC.day = day
            vc.workoutAC.day = day
        }
        
    }
    
}

//
//  DayViewController.swift
//  WorkoutEditor
//
//  Created by Steven Lord on 11/09/2019.
//  Copyright © 2019 Steven Lord. All rights reserved.
//

import Cocoa

class DayViewController: NSViewController {

    var mainViewController: ViewController?
    @IBOutlet var readingsAC: ReadingsArrayController!
    @IBOutlet var workoutAC: WorkoutArrayController!
    @IBOutlet var workoutComments: NSTextView!
    @objc var selectedWorkout: Workout?
    
    @IBOutlet weak var tmpField: NSTextField!
    
    @IBAction func save(_ sender: Any) {
        if let day = representedObject as? Day{
            if let td = trainingDiary{
                td.save(day: day)
            }
        }
    }
    
    @IBAction func test(_ sender: Any) {
        if let d = representedObject as? Day{
            print(d.comments)
        }
    }
    
    @objc var trainingDiary: TrainingDiary?{
        if let d = representedObject as? Day{
            return d.trainingDiary
        }
        return nil
    }
    
    @objc var day: Day?{
        return representedObject as? Day
    }
}

extension DayViewController: NSComboBoxDataSource{
    func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        var types: [String] = []
        switch comboBox.identifier?.rawValue{
        case "dayType":         types = trainingDiary?.dayTypes ?? []
        case "readingType":     types = day?.unusedReadingStrings ?? []
        case "activity":        types = trainingDiary?.activities ?? []
        case "activityType":    types = trainingDiary?.activityTypes ?? []
        case "equipment":       types = trainingDiary?.equipmentTypes ?? []
        case "tssMethod":       types = trainingDiary?.tssMethods ?? []
        default:                types = []
        }
        if types.count > index{
            return types[index]
        }else{
            return nil
        }
    }

    
    func numberOfItems(in comboBox: NSComboBox) -> Int {
        switch comboBox.identifier?.rawValue{
        case "dayType":         return trainingDiary?.dayTypes.count ?? 0
        case "readingType":     return day?.unusedReadingStrings.count ?? 0
        case "activity":        return trainingDiary?.activities.count ?? 0
        case "activityType":    return trainingDiary?.activityTypes.count ?? 0
        case "equipment":       return trainingDiary?.equipmentTypes.count ?? 0
        case "tssMethod":       return trainingDiary?.tssMethods.count ?? 0
        default:
            return 0
        }
    }
    
    
}


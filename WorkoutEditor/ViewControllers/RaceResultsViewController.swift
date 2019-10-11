//
//  RaceResultsViewController.swift
//  WorkoutEditor
//
//  Created by Steven Lord on 16/09/2019.
//  Copyright © 2019 Steven Lord. All rights reserved.
//

import Cocoa

class RaceResultsViewController: NSViewController {

    @objc dynamic var trainingDiary: TrainingDiary?
    
    @IBOutlet weak var races: NSTableView!
    @IBOutlet var raceResultsAC: RaceResultsArrayController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        trainingDiary = parent?.parent?.representedObject as? TrainingDiary
        if let rac = raceResultsAC{
            rac.trainingDiary = trainingDiary
        }
        // Do view setup here.
    }
    
    @IBAction func saveRaceResult(_ sender: Any) {
        if let rr = raceResultsAC.selectedObjects as? [RaceResult]{
            for r in rr{
                WorkoutDBAccess.shared.save(raceResult: r)
            }
        }
    }
    
    @IBAction func exportSelection(_ sender: Any){
        if let url = OpenAndSaveDialogues().saveFilePath(suggestedFileName: "RaceResults", allowFileTypes: ["json"], directory: nil){
            
            if let raceResults = raceResultsAC.selectedObjects as? [RaceResult]{
                  if let jsonString = JSONExporter().createJSON(forDays: [], raceResults: raceResults){
                      do{
                          try jsonString.write(to: url, atomically: true, encoding: String.Encoding.utf8.rawValue)
                      }catch{
                          print("Unable to save JSON")
                          print(error)
                      }
                  }
            }
        }
    }
}

extension RaceResultsViewController: NSComboBoxDataSource{
    
    func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        var types: [String] = []
        switch comboBox.identifier?.rawValue{
        case "raceType":        types = trainingDiary?.raceTypes ?? []
        case "raceBrand":       types = trainingDiary?.raceBrands ?? []
        case "raceDistance":    types = trainingDiary?.raceDistances ?? []
        case "ageCategory":     types = trainingDiary?.ageCategories ?? []
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
        case "raceType":        return trainingDiary?.raceTypes.count ?? 0
        case "raceBrand":       return trainingDiary?.raceBrands.count ?? 0
        case "raceDistance":    return trainingDiary?.raceDistances.count ?? 0
        case "ageCategory":     return trainingDiary?.ageCategories.count ?? 0
        default:
            return 0
        }
    }
    
}

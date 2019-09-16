//
//  RaceResultsArrayController.swift
//  WorkoutEditor
//
//  Created by Steven Lord on 16/09/2019.
//  Copyright © 2019 Steven Lord. All rights reserved.
//

import Cocoa

class RaceResultsArrayController: NSArrayController {

    var trainingDiary: TrainingDiary?
    
    override func newObject() -> Any {
        if let td = trainingDiary{
            return td.defaultNewRaceResult()
        }else{
            return super.newObject()
        }
    }
    
    override func remove(_ sender: Any?) {
        if let results = selectedObjects as? [RaceResult]{
            if results.count > 0{
                WorkoutDBAccess.shared.delete(raceResult: results[0])
            }
        }
        super.remove(sender)
    }
    
}

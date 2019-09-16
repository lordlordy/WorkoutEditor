//
//  WorkoutArrayController.swift
//  WorkoutEditor
//
//  Created by Steven Lord on 11/09/2019.
//  Copyright © 2019 Steven Lord. All rights reserved.
//

import Cocoa

class WorkoutArrayController: NSArrayController {
    
    var day: Day?
        
    override func newObject() -> Any {
        if let d = day{
            d.unsavedChanges = true
            return d.defaultWorkout()
        }else{
            return super.newObject()
        }
    }
    
    override func remove(_ sender: Any?) {
        if let workouts = selectedObjects as? [Workout]{
            if workouts.count > 0{
                WorkoutDBAccess.shared.delete(workout: workouts[0])
            }
        }
        super.remove(sender)
    }
        
}

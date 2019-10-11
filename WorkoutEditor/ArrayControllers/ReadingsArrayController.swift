//
//  ReadingsArrayController.swift
//  WorkoutEditor
//
//  Created by Steven Lord on 11/09/2019.
//  Copyright © 2019 Steven Lord. All rights reserved.
//

import Cocoa

class ReadingsArrayController: NSArrayController {

    var day: Day?

    override func newObject() -> Any {
        return day!.defaultReading()        
    }
    
}

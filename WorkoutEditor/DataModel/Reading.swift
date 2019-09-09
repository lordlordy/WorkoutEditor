//
//  DayReading.swift
//  WorkoutEditor
//
//  Created by Steven Lord on 30/08/2019.
//  Copyright © 2019 Steven Lord. All rights reserved.
//

import Foundation

class Reading{
    
    var date: Date{ return day.date }
    var type: String
    var value: Double
    var day: Day
    var description: String{ return "\(type):\(value)"}
    
    init(type: String, value: Double, parent: Day){
        self.type = type
        self.value = value
        self.day = parent
    }
    
    
    
    
    
}

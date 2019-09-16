//
//  DayReading.swift
//  WorkoutEditor
//
//  Created by Steven Lord on 30/08/2019.
//  Copyright © 2019 Steven Lord. All rights reserved.
//

import Foundation

class Reading: NSObject{
    
    @objc var pk: String { return "\(day.iso8601DateString)-\(type)" }
    @objc var date: Date{ return day.date }
    @objc var type: String
    @objc var value: Double
    @objc var day: Day
    override var description: String{ return "\(type):\(value)"}
    
    
    init(type: String, value: Double, parent: Day){
        self.type = type
        self.value = value
        self.day = parent
    }
    
}

extension Reading{
    override func setValue(_ value: Any?, forKey key: String) {
        super.setValue(value, forKey: key)
        day.unsavedChanges = true
    }
}

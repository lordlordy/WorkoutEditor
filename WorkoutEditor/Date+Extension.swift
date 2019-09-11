//
//  Date+Extension.swift
//  WorkoutEditor
//
//  Created by Steven Lord on 10/09/2019.
//  Copyright © 2019 Steven Lord. All rights reserved.
//

import Foundation

extension Date{
   
    var year: Int{ return Calendar.current.dateComponents([.year], from: self).year ?? 0 }
    
    var monthAsString: String{
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: self)
    }
    
    //return start of day - ie time component 00:00:00
    var startOfDay: Date{
        var dc = Calendar.current.dateComponents([.day, .month,.year], from: self)
        dc.hour = 0
        dc.minute = 0
        dc.second = 0
        return Calendar.current.date(from: dc)!
    }
    
    var endOfDay: Date{
        var dc = Calendar.current.dateComponents([.day, .month,.year], from: self)
        dc.hour = 23
        dc.minute = 59
        dc.second = 59
        return Calendar.current.date(from: dc)!
    }
    
    
    var startOfYear: Date{
        var dc = Calendar.current.dateComponents([.day, .month,.year], from: self)
        dc.day = 1
        dc.month = 1
        dc.hour = 0
        dc.minute = 0
        dc.second = 0
        return Calendar.current.date(from: dc)!
    }
    
    var endOfYear: Date{
        var dc = Calendar.current.dateComponents([.day, .month,.year], from: self)
        dc.day = 31
        dc.month = 12
        dc.hour = 23
        dc.minute = 59
        dc.second = 59
        return Calendar.current.date(from: dc)!
    }
    
    var startOfMonth: Date{
        var dc = Calendar.current.dateComponents([.day, .month,.year], from: self)
        dc.day = 1
        dc.hour = 0
        dc.minute = 0
        dc.second = 0
        return Calendar.current.date(from: dc)!
    }
    
    var endOfMonth: Date{
        let components = DateComponents(day:1)
        let startOfNextMonth = Calendar.current.nextDate(after:self, matching: components, matchingPolicy: .nextTime)!
        let d = Calendar.current.date(byAdding:.day, value: -1, to: startOfNextMonth)!
        return d.endOfDay
    }
    
    var startOfWeek: Date{
        return Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self))!
    }
    
    var endOfWeek: Date{
        return Calendar.current.date(byAdding: DateComponents(day: 6), to: startOfWeek)!
    }
    
    var weekOfYear: Int{
        let dc = Calendar.current.dateComponents([.weekOfYear], from: self)
        return dc.weekOfYear!
    }
    
    var yearForWeekOfYear: Int{
        let dc = Calendar.current.dateComponents([.yearForWeekOfYear], from: self)
        return dc.yearForWeekOfYear!
    }
    
}

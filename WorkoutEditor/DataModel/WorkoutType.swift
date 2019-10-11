//
//  WorkoutType.swift
//  WorkoutEditor
//
//  Created by Steven Lord on 12/09/2019.
//  Copyright © 2019 Steven Lord. All rights reserved.
//

import Foundation

struct WorkoutType: Hashable{
    
    var activity: String?
    var activityType: String?
    var equipment: String?
    
    init(activity a: String?, activityType at: String?, equipment e: String?){
        activity = convert(str: a)
        activityType = convert(str: at)
        equipment = convert(str: e)
    }
    
    var name: String{
        var components: [String] = [activity ?? "All", activityType ?? "All"]
        if equipment == nil{
            components.append("All")
        }else{
            let eNoSpaces: String = equipment!.replacingOccurrences(of: " ", with: "")
            components.append(eNoSpaces)
        }
        return components.joined(separator: "_")
    }
    
    private func convert(str s: String?) -> String?{
        // this returns nil if s is nil or "" or "All" otherwise returns the string
        if let str = s{
            if str == "" || str == "All"{
                return nil
            }
        }
        return s
    }
}

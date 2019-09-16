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
    
    var name: String{
        var components: [String] = [activity ?? "All", activityType ?? "All"]
        if equipment == nil || equipment == ""{
            components.append("All")
        }else{
            let eNoSpaces: String = equipment!.replacingOccurrences(of: " ", with: "")
            components.append(eNoSpaces)
        }
        return components.joined(separator: "_")
    }
}

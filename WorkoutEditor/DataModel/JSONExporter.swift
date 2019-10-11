//
//  JSONExporter.swift
//  WorkoutEditor
//
//  Created by Steven Lord on 16/09/2019.
//  Copyright © 2019 Steven Lord. All rights reserved.
//

import Foundation

class JSONExporter{
    
    static let currentVersion: String  = "WorkoutEditor_v1"
    
    public func createJSON(forDays days: [Day], raceResults results: [RaceResult]) -> NSString?{
        var daysArray: [[String:Any]] = []
        
        var trainingDiaryDictionary: [String:Any] = ["JSONVersion": JSONExporter.currentVersion,
                                                     "Created": ISO8601DateFormatter().string(from: Date())]
        
        for d in days.sorted(by: {$0.date > $1.date}){
            var dDict = d.dictionaryWithValues(forKeys: DayJSONProperty.allCases.map({$0.rawValue}))
            if d.workouts.count > 0{
                dDict["Workouts"] = d.workouts.map({$0.dictionaryWithValues(forKeys: WorkoutJSONProperty.allCases.map({$0.rawValue}))})
            }
            if d.readings.count > 0{
                dDict["Readings"] = d.readings.map({$0.dictionaryWithValues(forKeys: ReadingJSONProperty.allCases.map({$0.rawValue}))})
            }
            daysArray.append(dDict)
        }
        
        if results.count > 0{
            trainingDiaryDictionary["RaceResults"] = results.map({$0.dictionaryWithValues(forKeys: RaceResultJSONProperty.allCases.map({$0.rawValue}))})
        }
        
        if daysArray.count > 0{
            trainingDiaryDictionary["Days"] = daysArray
        }
                
        do {
            let data = try JSONSerialization.data(withJSONObject: trainingDiaryDictionary, options: .prettyPrinted)
            let jsonString = NSString.init(data: data, encoding: String.Encoding.utf8.rawValue)
            return jsonString
            
        } catch {
            print("JSON export failed with error \(error)")
        }
        return nil
    }
    
}

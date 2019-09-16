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
    
    public func createJSON(forDays days: [Day]) -> NSString?{
        var daysArray: [[String:Any]] = []
        
        var trainingDiaryDictionary: [String:Any] = ["JSONVersion": JSONExporter.currentVersion,
                                                     "Created": ISO8601DateFormatter().string(from: Date())]
        
        for d in days.sorted(by: {$0.date > $1.date}){
            var dDict = d.dictionaryWithValues(forKeys: DayJSONProperty.allCases.map({$0.rawValue}))
            let workouts = createWorkoutsArray(forWorkouts: d.workouts)
            let readings = createReadingsArray(forReading: d.readings)
            if workouts.count > 0{
                dDict["Workouts"] = createWorkoutsArray(forWorkouts: d.workouts)
            }
            if readings.count > 0{
                dDict["Readings"] = createReadingsArray(forReading: d.readings)
            }
            daysArray.append(dDict)
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
    
    
    private func createWorkoutsArray(forWorkouts workouts: [Workout]) -> [[String: Any]]{
        var result: [[String:Any]] = []
        
        for w in workouts{
            result.append(w.dictionaryWithValues(forKeys: WorkoutJSONProperty.allCases.map({$0.rawValue})))
        }
        
        return result
    }

    private func createReadingsArray(forReading readings: [Reading]) -> [[String: Any]]{
        var result: [[String:Any]] = []
        
        for r in readings{
            result.append(r.dictionaryWithValues(forKeys: ReadingJSONProperty.allCases.map({$0.rawValue})))
        }
        
        return result
    }
    
}

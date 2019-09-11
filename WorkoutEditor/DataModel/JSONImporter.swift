//
//  JSONImporter.swift
//  WorkoutEditor
//
//  Created by Steven Lord on 09/09/2019.
//  Copyright © 2019 Steven Lord. All rights reserved.
//

import Foundation

class JSONImporter{
    
    private var progressUpdater: ((Double) -> Void)?
    
    init(progressUpdater updater: ((Double) -> Void)?){
        progressUpdater = updater
    }
    
    public func importDiary(fromURL url: URL, intoTrainingDiary td: TrainingDiary){
        let start: Date = Date()
        do{
            let data: Data = try Data.init(contentsOf: url)
            let jsonData  = try JSONSerialization.jsonObject(with: data, options: [.allowFragments, .mutableContainers])
            let jsonDict = jsonData as? [String:Any]

            var total: Double = Double((jsonDict?["days"] as? [Any])?.count ?? 0)
            total += Double((jsonDict?["weights"] as? [Any])?.count ?? 0)
            total += Double((jsonDict?["physiologicals"] as? [Any])?.count ?? 0)
            var progress: Double = 0.0

            if let days = jsonDict?["days"] as? [[String:Any]]{
                for d in days{
                    let day: Day = Day(date: ISO8601DateFormatter().date(from: d["iso8061DateString"] as! String)!, type: d["type"] as! String, comments: d["comments"] as? String ?? "", trainingDiary: td)
                    if Calendar.current.compare(day.date, to: Calendar.current.date(from: DateComponents(year: 2005, month: 01, day: 02))!, toGranularity: .day) == ComparisonResult.orderedSame{
                        print("found that date")
                    }
                    WorkoutDBAccess.shared.save(day: day)
                    
                    WorkoutDBAccess.shared.save(reading: Reading(type: "sleep", value: d["sleep"] as! Double, parent: day))
                    WorkoutDBAccess.shared.save(reading: Reading(type: "fatigue", value: d["fatigue"] as! Double, parent: day))
                    WorkoutDBAccess.shared.save(reading: Reading(type: "motivation", value: d["motivation"] as! Double, parent: day))
                    WorkoutDBAccess.shared.save(reading: Reading(type: "sleepQuality", value: sleepQualityScore(forQuality: d["sleepQuality"] as! String), parent: day))

                    if let workouts = d["workouts"] as? [[String:Any]]{
                        var workout_number: Int = 1
                        for w in workouts{
                            let wOut = workout(fromDict: w, andDay: day, workout_number: workout_number)
                            WorkoutDBAccess.shared.save(workout: wOut)
                            day.add(workout: wOut)
                            workout_number += 1
                        }
                    }
                    
                    print(day.description)
                    progress += 1.0
                    if let p = progressUpdater{
                        p(progress / total)
                    }
                }
            }
            
            if let weights = jsonDict?["weights"] as? [[String:Any]]{
                for w in weights{
                    // just set up dummy day for the save
                    let day: Day = Day(date: ISO8601DateFormatter().date(from: w["iso8061DateString"] as! String)!, type: "", comments: "", trainingDiary: td)
                    
                    WorkoutDBAccess.shared.save(reading: Reading(type: "kg", value: w["kg"] as! Double, parent: day))
                    WorkoutDBAccess.shared.save(reading: Reading(type: "fatPercentage", value: w["fatPercent"] as! Double, parent: day))
                    progress += 1.0
                    if let p = progressUpdater{
                        p(progress / total)
                    }
                }
            }

            if let physiologicals = jsonDict?["physiologicals"] as? [[String:Any]]{
                for physio in physiologicals{
                    // just set up dummy day for the save
                    let day: Day = Day(date: ISO8601DateFormatter().date(from: physio["iso8061DateString"] as! String)!, type: "", comments: "", trainingDiary: td)
                    
                    WorkoutDBAccess.shared.save(reading: Reading(type: "restingHR", value: physio["restingHR"] as! Double, parent: day))
                    if let rmssd = physio["restingRMSSD"] as? Double{
                        WorkoutDBAccess.shared.save(reading: Reading(type: "rMSSD", value: rmssd, parent: day))
                    }
                    if let sdnn = physio["restingSDNN"] as? Double{
                        WorkoutDBAccess.shared.save(reading: Reading(type: "SDNN", value: sdnn, parent: day))
                    }
                    progress += 1.0
                    if let p = progressUpdater{
                        p(progress / total)
                    }
                }
            }


        }catch{
            print("error initialising Training Diary for URL: " + url.absoluteString)
        }
        
        print("import took \(Int(Date().timeIntervalSince(start)))s")
    }
    
    private func workout(fromDict dict: [String: Any], andDay day: Day, workout_number: Int) -> Workout{
        var equip: String = ""
        if let e = dict["equipmentName"] as? String{
            if e != "Not Set"{
                equip = e
            }
        }
        return Workout(day: day,
                       workout_number: workout_number,
                       activity: dict["activityString"] as! String,
                       activity_type: dict["activityTypeString"] as! String,
                       equipment: equip,
                       seconds: dict["seconds"] as! Int,
                       rpe: dict["rpe"] as! Double,
                       tss: dict["tss"] as! Double,
                       tss_method: dict["tssMethod"] as! String,
                       km: dict["km"] as! Double,
                       kj: dict["kj"] as! Double,
                       ascent_metres: dict["ascentMetres"] as! Double,
                       reps: dict["reps"] as! Int,
                       is_race: (dict["isRace"] as! Int > 0),
                       cadence: dict["cadence"] as! Int,
                       watts: dict["watts"] as! Double,
                       watts_estimated: (dict["wattsEstimated"] as! Int > 0),
                       heart_rate: Int(dict["hr"] as! Double),
                       is_brick: (dict["brick"] as! Int > 0),
                       keywords: dict["keywords"] as? String ?? "",
                       comments: dict["comments"] as? String ?? "")
    }
    
    private func sleepQualityScore(forQuality quality: String) -> Double{
        switch quality{
        case "Excellent": return 1.0
        case "Good": return 0.75
        case "Average": return 0.5
        case "Poor": return 0.3
        case "Very Poor": return 0.1
        default: return 0.0
        }
    }
    
}

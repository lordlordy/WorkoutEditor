//
//  Workout.swift
//  WorkoutEditor
//
//  Created by Steven Lord on 30/08/2019.
//  Copyright © 2019 Steven Lord. All rights reserved.
//

import Foundation

class Workout: NSObject{
    @objc var day: Day
    @objc var date: Date { return day.date }
    @objc var workoutNumber: Int
    @objc var activity: String
    @objc var activityType: String
    @objc var equipment: String
    @objc var seconds: Int{
        didSet{
            setRPETSS()
        }
    }
    @objc var rpe: Double{
        didSet{
            setRPETSS()
        }
    }
    @objc var tss: Double
    @objc var tssMethod: String
    @objc var km: Double
    @objc var kj: Double
    @objc var ascentMetres: Double
    @objc var reps: Int
    @objc var isRace: Bool
    @objc var cadence:Int
    @objc var watts: Double
    @objc var wattsEstimated: Bool
    @objc var heartRate: Int
    @objc var isBrick: Bool
    @objc var keywords: String
    @objc var comments: String
    
    @objc dynamic var rpeTSS: Double = 0.0

    
    init(day: Day, workout_number: Int, activity: String, activity_type: String, equipment: String, seconds: Int, rpe: Double, tss: Double, tss_method: String, km: Double, kj: Double, ascent_metres: Double, reps: Int, is_race: Bool, cadence:Int, watts: Double, watts_estimated: Bool, heart_rate: Int, is_brick: Bool, keywords: String, comments: String){
        self.day = day
        self.workoutNumber = workout_number
        self.activity = activity
        self.activityType = activity_type
        self.equipment = equipment
        self.seconds = seconds
        self.rpe = rpe
        self.tss = tss
        self.tssMethod = tss_method
        self.km = km
        self.kj = kj
        self.ascentMetres = ascent_metres
        self.reps = reps
        self.isRace = is_race
        self.cadence = cadence
        self.watts = watts
        self.wattsEstimated = watts_estimated
        self.heartRate = heart_rate
        self.isBrick = is_brick
        self.keywords = keywords
        self.comments = comments
        rpeTSS = (100/49)*rpe*rpe*Double(seconds)/3600
    }
    
    private func setRPETSS(){
        rpeTSS = (100/49)*rpe*rpe*Double(seconds)/3600
    }

}

extension Workout: PeriodNode{
    var name: String { return "\(activity):\(activityType):\(equipment)" }
    var children: [PeriodNode] { return [] }
    var childCount: Int { return 0 }
    var totalKM: Double { return km }
    var totalSeconds: TimeInterval { return TimeInterval(seconds) }
    var totalTSS: Double { return tss }
    var swimKM: Double { return activity.uppercased() == "SWIM" ? km : 0.0 }
    var swimSeconds: TimeInterval { return activity.uppercased() == "SWIM" ? totalSeconds : 0.0 }
    var swimTSS: Double { return activity.uppercased() == "SWIM" ? tss : 0.0 }
    var bikeKM: Double { return activity.uppercased() == "BIKE" ? km : 0.0 }
    var bikeSeconds: TimeInterval { return activity.uppercased() == "BIKE" ? totalSeconds : 0.0 }
    var bikeTSS: Double {return activity.uppercased() == "BIKE" ? tss : 0.0 }
    var runKM: Double {return activity.uppercased() == "RUN" ? km : 0.0 }
    var runSeconds: TimeInterval { return activity.uppercased() == "RUN" ? totalSeconds : 0.0 }
    var runTSS: Double { return activity.uppercased() == "RUN" ? tss : 0.0 }
    var fromDate: Date { return date }
    var toDate: Date { return date }
    var isLeaf: Bool { return true }
    var leafCount: Int { return 0 }
    
    @objc var type: String {
        var s: [String] = [activity]
        if isRace{ s.append("Race") }
        if isBrick{ s.append("Brick")}
        return s.joined(separator: " ")
        
    }
    
    @objc var sleep:            Double      { return 0.0 }
    @objc var sleepQuality:     Double      { return 0.0 }
    @objc var motivation:       Double      { return 0.0 }
    @objc var fatigue:          Double      { return 0.0 }
    @objc var kg:               Double      { return 0.0 }
    @objc var fatPercentage:    Double      { return 0.0 }
    @objc var restingHR:        Double      { return 0.0 }
    @objc var sdnn:             Double      { return 0.0 }
    @objc var rMSSD:            Double      { return 0.0 }
    
    
}

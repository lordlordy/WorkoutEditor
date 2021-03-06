//
//  Workout.swift
//  WorkoutEditor
//
//  Created by Steven Lord on 30/08/2019.
//  Copyright © 2019 Steven Lord. All rights reserved.
//

import Foundation
import CloudKit

@objc class Workout: NSObject{
    
    private let milesPerKM: Double = 0.621371
    private let feetPerMetre: Double = 3.28084
    
    @objc var primaryKey: String{
        return "\(day.iso8601DateString)-\(String(workoutNumber))"
    }
    @objc var primary_key: String{ return self.primaryKey }
    
    @objc var day: Day
    @objc var date: Date { return day.date }
    @objc var workoutNumber: Int
    @objc var workout_number: Int { return self.workoutNumber }
    @objc var activity: String
    @objc var activityType: String
    @objc var activity_type: String { return self.activityType }
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
    @objc var tss: Int
    @objc var tssMethod: String
    @objc var tss_method: String { return self.tssMethod }
    @objc var km: Double
    @objc var kj: Int
    @objc var ascentMetres: Int
    @objc var ascent_metres: Int { return self.ascentMetres }
    @objc var reps: Int
    @objc var isRace: Bool
    @objc var is_race: Bool { return self.isRace }
    @objc var cadence:Int
    @objc var watts: Int
    @objc var wattsEstimated: Bool
    @objc var watts_estimated: Bool { return self.wattsEstimated }
    @objc var heartRate: Int
    @objc var heart_rate: Int { return self.heartRate }
    @objc var isBrick: Bool
    @objc var is_brick: Bool { return self.isBrick }
    @objc var keywords: String
    @objc dynamic var comments: String
    @objc var lastSave: Date? = nil
    @objc var last_save: Date? { return self.lastSave }
    @objc var lastSaveString: String{
        if let d = lastSave{
            return ISO8601DateFormatter().string(from: d)
        }else{
            return ""
        }
    }
    
    @objc dynamic var rpeTSS: Int = 0

    @objc dynamic var pressUps: Int {
        if self.activity_type.lowercased() == "pressup"{
            return self.reps
        }else{
            return 0
        }
    }
    
    var unsavedChanges: Bool = false
    
    // nb to 2 dp
    var miles: Double{ return round(km * milesPerKM * 100) / 100 }
    var ascentFeet: Int { return Int(Double(ascentMetres) * feetPerMetre)}

    @objc var ctl: Double = 0.0
    @objc var atl: Double = 0.0
    @objc var tsb: Double{ return ctl - atl }
    
    @objc var ctlSwim: Double = 0.0
    @objc var atlSwim: Double = 0.0
    @objc var tsbSwim: Double{ return ctlSwim - atlSwim }
    
    @objc var ctlBike: Double = 0.0
    @objc var atlBike: Double = 0.0
    @objc var tsbBike: Double{ return ctlBike - atlBike }
    
    @objc var ctlRun: Double = 0.0
    @objc var atlRun: Double = 0.0
    @objc var tsbRun: Double{ return ctlRun - atlRun }
    
    init(day: Day, workout_number: Int, activity: String, activity_type: String, equipment: String, seconds: Int, rpe: Double, tss: Int, tss_method: String, km: Double, kj: Int, ascent_metres: Int, reps: Int, is_race: Bool, cadence:Int, watts: Int, watts_estimated: Bool, heart_rate: Int, is_brick: Bool, keywords: String, comments: String){
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
        rpeTSS = Int((100/49)*rpe*rpe*Double(seconds)/3600)
    }
    
    func isType(workoutType wt: WorkoutType) -> Bool{
        let correctActivity: Bool = wt.activity == nil || wt.activity == activity
        let correctActivityType: Bool = wt.activityType == nil || wt.activityType == activityType
        let correctEquipment: Bool = wt.equipment == nil || wt.equipment == equipment
        return correctActivity && correctActivityType && correctEquipment
    }
    
    var types: Set<WorkoutType>{
        var values: Set<WorkoutType> = [WorkoutType(activity: nil, activityType: nil, equipment: nil),
                                        WorkoutType(activity: nil, activityType: activityType, equipment: nil),
                                        WorkoutType(activity: activity, activityType: nil, equipment: nil),
                                        WorkoutType(activity: activity, activityType: activityType, equipment: nil)]
        if equipment != ""{
            values.insert(WorkoutType(activity: nil, activityType: nil, equipment: equipment))
            values.insert(WorkoutType(activity: nil, activityType: activityType, equipment: equipment))
            values.insert(WorkoutType(activity: activity, activityType: nil, equipment: equipment))
            values.insert(WorkoutType(activity: activity, activityType: activityType, equipment: equipment))
        }
        return values
    }
    
    private func setRPETSS(){
        rpeTSS = Int((100/49)*rpe*rpe*Double(seconds)/3600)
    }

}

extension Workout: PeriodNode{

    var name: String { return "\(activity):\(activityType):\(equipment)" }
    var children: [PeriodNode] { return [] }
    var childCount: Int { return 0 }
    var totalKM: Double { return km }
    var totalSeconds: TimeInterval { return TimeInterval(seconds) }
    var totalTSS: Int { return tss }
    var swimKM: Double { return activity.uppercased() == "SWIM" ? km : 0.0 }
    var swimSeconds: TimeInterval { return activity.uppercased() == "SWIM" ? totalSeconds : 0.0 }
    var swimTSS: Int { return activity.uppercased() == "SWIM" ? tss : 0 }
    var bikeKM: Double { return activity.uppercased() == "BIKE" ? km : 0.0 }
    var bikeSeconds: TimeInterval { return activity.uppercased() == "BIKE" ? totalSeconds : 0.0 }
    var bikeTSS: Int {return activity.uppercased() == "BIKE" ? tss : 0 }
    var runKM: Double {return activity.uppercased() == "RUN" ? km : 0.0 }
    var runSeconds: TimeInterval { return activity.uppercased() == "RUN" ? totalSeconds : 0.0 }
    var runTSS: Int { return activity.uppercased() == "RUN" ? tss : 0 }
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
    @objc var sleepQualityScore:Double      { return 0.0 }
    @objc var motivation:       Double      { return 0.0 }
    @objc var fatigue:          Double      { return 0.0 }
    @objc var kg:               Double      { return 0.0 }
    @objc var fatPercentage:    Double      { return 0.0 }
    @objc var restingHR:        Int         { return 0 }
    @objc var sdnn:             Double      { return 0.0 }
    @objc var rMSSD:            Double      { return 0.0 }
    @objc var days:             Set<Day>    { return Set([day])}
    
    
}

extension Workout{
    override func setValue(_ value: Any?, forKey key: String) {
        super.setValue(value, forKey: key)
        day.unsavedChanges = true
        self.unsavedChanges = true
    }
}

extension Workout: AsCloudKitProtocol{
    func asCKRecord() -> CKRecord {

        let record: CKRecord = CKRecord(recordType: TableName.Workout.rawValue, recordID: ckRecordID())
        
        for c in WorkoutColumn.allCases{
            record.setValue(self.value(forKey: c.rawValue), forKey: c.rawValue)
        }
        
        record["day"] = CKRecord.Reference(recordID: self.day.ckRecordID(), action: .deleteSelf)
        
        return record
    }
    
    func ckRecordID() -> CKRecord.ID {
        return CKRecord.ID(recordName: self.primaryKey, zoneID: CKRecordZone.default().zoneID)
    }
    
    
}

//
//  Day.swift
//  WorkoutEditor
//
//  Created by Steven Lord on 30/08/2019.
//  Copyright © 2019 Steven Lord. All rights reserved.
//

import Foundation
import CloudKit

@objc class Day: NSObject{
    @objc var date: Date
    @objc var type: String
    @objc dynamic var comments: String
    @objc dynamic var readings: [Reading] = []
    @objc dynamic var workouts: [Workout] = []
    var unusedReadingStrings: [String]{
        let usedTypes: Set<String> = Set(readings.map({$0.type}))
        let allTypes: Set<String> = trainingDiary.readingTypes
        return Array(allTypes.subtracting(usedTypes)).sorted(by: {$0 < $1})
    }
    
    @objc dynamic var unsavedChanges: Bool = false
    
    private var readingDictionary: [String: Reading] = [:]
    var readingCount: Int{ return readings.count}
    var workoutCount: Int{ return workouts.count}
    
    var trainingDiary: TrainingDiary
    
    var swimKM: Double { return workouts.filter({$0.activity == "Swim"}).reduce(0.0, {$0 + $1.km})}
    var bikeKM: Double { return workouts.filter({$0.activity == "Bike"}).reduce(0.0, {$0 + $1.km})}
    var runKM: Double { return workouts.filter({$0.activity == "Run"}).reduce(0.0, {$0 + $1.km})}
    var totalHours: Double { return Double(workouts.reduce(0, {$0 + $1.seconds}))/3600.0}
    
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
    
    @objc var iso8601DateString: String{
        let df: DateFormatter = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df.string(from: date)
    }
    
    override var description: String{
        let s: String = readingDescriptions().joined(separator: ", ")
        return "\(date): \(type) workouts:\(workouts.count) \(s)"
    }
    
    init(date: Date, type: String, comments: String, trainingDiary td: TrainingDiary){
        self.date = date
        self.type = type
        self.comments = comments
        trainingDiary = td
    }
    
    func add(workout: Workout){
        workouts.append(workout)
        workout.day = self
    }
    
    func add(readings dayReadings: [Reading]){
        for r in dayReadings{
            readingDictionary[r.type] = r
            r.day = self
            readings.append(r)
        }
    }
    
    func defaultReading() -> Reading{
        return Reading(type: "", value: 0.0, parent: self)
    }
    
    func defaultWorkout() -> Workout{
        let w = Workout(day: self, workout_number: workouts.count + 1, activity: "Swim", activity_type: "Squad", equipment: "", seconds: 0, rpe: 5.0, tss: 50, tss_method: "PacePower", km: 0.0, kj: 0, ascent_metres: 0, reps: 0, is_race: false, cadence: 0, watts: 0, watts_estimated: true, heart_rate: 0, is_brick: false, keywords: "", comments: "")
        return w
    }

    func reading(forType type: String) -> Reading?{
        return readingDictionary[type]
    }
    
    func readingDescriptions() -> [String]{
        return readingDictionary.values.map({$0.description})
    }
    
    var workoutTypes: Set<WorkoutType>{
        var result: Set<WorkoutType> = []
        for w in workouts{
            result = result.union(w.types)
        }
        return result
    }
    
    func workoutsFor(type: WorkoutType) -> [Workout]{
        return workouts.filter({$0.isType(workoutType: type)})
    }
    
}

extension Day: PeriodNode{
    var name: String {
        let df: DateFormatter = DateFormatter()
        df.dateFormat = "dd E"
        return df.string(from: date)
    }
    
    @objc dynamic var children: [PeriodNode] { return workouts }
    var childCount: Int { return workoutCount }
    var totalKM: Double { return workouts.reduce(0.0, {$0 + $1.km}) }
    var totalSeconds: TimeInterval { return TimeInterval(workouts.reduce(0, {$0 + $1.seconds})) }
    var totalTSS: Int { return workouts.reduce(0, {$0 + $1.tss}) }
    var swimSeconds: TimeInterval { return TimeInterval(workouts.filter({$0.activity == "Swim"}).reduce(0, {$0 + $1.seconds})) }
    var swimTSS: Int { return workouts.filter({$0.activity == "Swim"}).reduce(0, {$0 + $1.tss}) }
    var bikeSeconds: TimeInterval { return TimeInterval(workouts.filter({$0.activity == "Bike"}).reduce(0, {$0 + $1.seconds})) }
    var bikeTSS: Int { return workouts.filter({$0.activity == "Bike"}).reduce(0, {$0 + $1.tss}) }
    var runSeconds: TimeInterval { return TimeInterval(workouts.filter({$0.activity == "Run"}).reduce(0, {$0 + $1.seconds})) }
    var runTSS: Int { return workouts.filter({$0.activity == "Run"}).reduce(0, {$0 + $1.tss}) }
    var fromDate: Date { return date }
    var toDate: Date { return date }
    var isLeaf: Bool { return workoutCount == 0 }
    var leafCount: Int { return workoutCount }
    var pressUps: Int { return workouts.reduce(0, {$0 + $1.pressUps})}

    @objc var sleep:            Double      { return reading(forType: "sleep")?.value ?? 0.0 }
    @objc var sleepQualityScore:Double      { return reading(forType: "sleepQualityScore")?.value ?? 0.0 }
    @objc var motivation:       Double      { return reading(forType: "motivation")?.value ?? 0.0 }
    @objc var fatigue:          Double      { return reading(forType: "fatigue")?.value ?? 0.0 }
    @objc var kg:               Double      { return reading(forType: "kg")?.value ?? 0.0 }
    @objc var fatPercentage:    Double      { return reading(forType: "fatPercentage")?.value ?? 0.0 }
    @objc var restingHR:        Int         { return Int(reading(forType: "restingHR")?.value ?? 0.0) }
    @objc var sdnn:             Double      { return reading(forType: "SDNN")?.value ?? 0.0 }
    @objc var rMSSD:            Double      { return reading(forType: "rMSSD")?.value ?? 0.0 }
    @objc var days:             Set<Day>    { return Set([self])}
    
}

extension Day{
    override func setValue(_ value: Any?, forKey key: String) {
        super.setValue(value, forKey: key)
        unsavedChanges = true
    }
}

extension Day: AsCloudKitProtocol{
    
    func asCKRecord() -> CKRecord{
        let record: CKRecord = CKRecord(recordType: TableName.Day.rawValue, recordID: ckRecordID())
        
        for c in DayColumn.allCases{
            record.setValue(self.value(forKey: c.rawValue), forKey: c.rawValue)
        }
        return record
    }
    
    func ckRecordID() -> CKRecord.ID {
        return CKRecord.ID(recordName: self.date.isoFormat, zoneID: CKRecordZone.default().zoneID)
    }

}

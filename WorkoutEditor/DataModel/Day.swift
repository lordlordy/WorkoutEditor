//
//  Day.swift
//  WorkoutEditor
//
//  Created by Steven Lord on 30/08/2019.
//  Copyright © 2019 Steven Lord. All rights reserved.
//

import Foundation

class Day: NSObject{
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
    
    
    private var readingDictionary: [String: Reading] = [:]
    private var workoutDictionary: [Int: Workout] = [:]
    var readingCount: Int{ return readingDictionary.count}
    var workoutCount: Int{ return workoutDictionary.count}
    
    var trainingDiary: TrainingDiary
    
    var swimKM: Double { return workoutDictionary.filter({$1.activity == "Swim"}).reduce(0.0, {$0 + $1.value.km})}
    var bikeKM: Double { return workoutDictionary.filter({$1.activity == "Bike"}).reduce(0.0, {$0 + $1.value.km})}
    var runKM: Double { return workoutDictionary.filter({$1.activity == "Run"}).reduce(0.0, {$0 + $1.value.km})}
    var totalHours: Double { return Double(workoutDictionary.reduce(0, {$0 + $1.value.seconds}))/3600.0}
    
    override var description: String{
        let s: String = readingDescriptions().joined(separator: ", ")
        return "\(date): \(type) workouts:\(workoutDictionary.count) \(s)"
    }
    
    init(date: Date, type: String, comments: String, trainingDiary td: TrainingDiary){
        self.date = date
        self.type = type
        self.comments = comments
        trainingDiary = td
    }
    
    func add(workout: Workout){
        if workoutDictionary[workout.workoutNumber] != nil{
            workout.workoutNumber = workouts.count
        }
        workoutDictionary[workout.workoutNumber] = workout
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
        return Workout(day: self, workout_number: workouts.count, activity: "Swim", activity_type: "Squad", equipment: "", seconds: 0, rpe: 5.0, tss: 50.0, tss_method: "PacePower", km: 0.0, kj: 0.0, ascent_metres: 0.0, reps: 0, is_race: false, cadence: 0, watts: 0, watts_estimated: true, heart_rate: 0, is_brick: false, keywords: "", comments: "")
    }

    func reading(forType type: String) -> Reading?{
        return readingDictionary[type]
    }
    
    func readingDescriptions() -> [String]{
        return readingDictionary.values.map({$0.description})
    }
    
}

extension Day: PeriodNode{
    var name: String {
        let df: DateFormatter = DateFormatter()
        df.dateFormat = "dd E"
        return df.string(from: date)
    }
    
    var children: [PeriodNode] {
        var result: [PeriodNode] = []
        for w in workoutDictionary.values{
            result.append(w)
        }
        return result
    }
    
    var childCount: Int { return workoutCount }
    var totalKM: Double { return workoutDictionary.reduce(0.0, {$0 + $1.value.km}) }
    var totalSeconds: TimeInterval { return TimeInterval(workoutDictionary.reduce(0, {$0 + $1.value.seconds})) }
    var totalTSS: Double { return workoutDictionary.reduce(0.0, {$0 + $1.value.tss}) }
    var swimSeconds: TimeInterval { return TimeInterval(workoutDictionary.filter({$1.activity == "Swim"}).reduce(0, {$0 + $1.value.seconds})) }
    var swimTSS: Double { return workoutDictionary.filter({$1.activity == "Swim"}).reduce(0.0, {$0 + $1.value.tss}) }
    var bikeSeconds: TimeInterval { return TimeInterval(workoutDictionary.filter({$1.activity == "Bike"}).reduce(0, {$0 + $1.value.seconds})) }
    var bikeTSS: Double { return workoutDictionary.filter({$1.activity == "Bike"}).reduce(0.0, {$0 + $1.value.tss}) }
    var runSeconds: TimeInterval { return TimeInterval(workoutDictionary.filter({$1.activity == "Run"}).reduce(0, {$0 + $1.value.seconds})) }
    var runTSS: Double { return workoutDictionary.filter({$1.activity == "Run"}).reduce(0.0, {$0 + $1.value.tss}) }
    var fromDate: Date { return date }
    var toDate: Date { return date }
    var isLeaf: Bool { return workoutCount == 0 }
    var leafCount: Int { return workoutCount }

    
    
    @objc var sleep:            Double      { return reading(forType: "sleep")?.value ?? 0.0 }
    @objc var sleepQuality:     Double      { return reading(forType: "sleepQuality")?.value ?? 0.0 }
    @objc var motivation:       Double      { return reading(forType: "motivation")?.value ?? 0.0 }
    @objc var fatigue:          Double      { return reading(forType: "fatigue")?.value ?? 0.0 }
    @objc var kg:               Double      { return reading(forType: "kg")?.value ?? 0.0 }
    @objc var fatPercentage:    Double      { return reading(forType: "fatPercentage")?.value ?? 0.0 }
    @objc var restingHR:        Double      { return reading(forType: "restingHR")?.value ?? 0.0 }
    @objc var sdnn:             Double      { return reading(forType: "SDNN")?.value ?? 0.0 }
    @objc var rMSSD:            Double      { return reading(forType: "rMSSD")?.value ?? 0.0 }
    
}

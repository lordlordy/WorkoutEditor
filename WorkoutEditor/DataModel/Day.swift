//
//  Day.swift
//  WorkoutEditor
//
//  Created by Steven Lord on 30/08/2019.
//  Copyright © 2019 Steven Lord. All rights reserved.
//

import Foundation

class Day{
    var date: Date
    var type: String
    var comments: String
    private var readings: [String: Reading] = [:]
    private var workouts: [Int: Workout] = [:]
    var readingCount: Int{ return readings.count}
    var workoutCount: Int{ return workouts.count}
    
    
    var swimKM: Double { return workouts.filter({$1.activity == "Swim"}).reduce(0.0, {$0 + $1.value.km})}
    var bikeKM: Double { return workouts.filter({$1.activity == "Bike"}).reduce(0.0, {$0 + $1.value.km})}
    var runKM: Double { return workouts.filter({$1.activity == "Run"}).reduce(0.0, {$0 + $1.value.km})}

    var description: String{
        let s: String = readingDescriptions().joined(separator: ", ")
        return "\(date): \(type) workouts:\(workouts.count) \(s)"
    }
    
    init(date: Date, type: String, comments: String){
        self.date = date
        self.type = type
        self.comments = comments
    }
    
    func add(workout: Workout){
        workouts[workout.workout_number] = workout
        workout.day = self
    }
    
    func add(readings dayReadings: [Reading]){
        for r in dayReadings{
            readings[r.type] = r
            r.day = self
        }
    }

    func reading(forType type: String) -> Reading?{
        return readings[type]
    }
    
    func readingDescriptions() -> [String]{
        return readings.values.map({$0.description})
    }
    
}

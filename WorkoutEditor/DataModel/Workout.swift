//
//  Workout.swift
//  WorkoutEditor
//
//  Created by Steven Lord on 30/08/2019.
//  Copyright © 2019 Steven Lord. All rights reserved.
//

import Foundation

class Workout{
    var day: Day
    var date: Date { return day.date }
    var workout_number: Int
    var activity: String
    var activity_type: String
    var equipment: String
    var seconds: Int
    var rpe: Double
    var tss: Double
    var tss_method: String
    var km: Double
    var kj: Double
    var ascent_metres: Double
    var reps: Int
    var is_race: Bool
    var cadence:Int
    var watts: Double
    var watts_estimated: Bool
    var heart_rate: Int
    var is_brick: Bool
    var keywords: String
    var comments: String
    
    init(day: Day, workout_number: Int, activity: String, activity_type: String, equipment: String, seconds: Int, rpe: Double, tss: Double, tss_method: String, km: Double, kj: Double, ascent_metres: Double, reps: Int, is_race: Bool, cadence:Int, watts: Double, watts_estimated: Bool, heart_rate: Int, is_brick: Bool, keywords: String, comments: String){
        self.day = day
        self.workout_number = workout_number
        self.activity = activity
        self.activity_type = activity_type
        self.equipment = equipment
        self.seconds = seconds
        self.rpe = rpe
        self.tss = tss
        self.tss_method = tss_method
        self.km = km
        self.kj = kj
        self.ascent_metres = ascent_metres
        self.reps = reps
        self.is_race = is_race
        self.cadence = cadence
        self.watts = watts
        self.watts_estimated = watts_estimated
        self.heart_rate = heart_rate
        self.is_brick = is_brick
        self.keywords = keywords
        self.comments = comments
    }
    
    
}

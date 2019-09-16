//
//  JSONProperties.swift
//  WorkoutEditor
//
//  Created by Steven Lord on 16/09/2019.
//  Copyright © 2019 Steven Lord. All rights reserved.
//

import Foundation

enum WorkoutJSONProperty: String,  CaseIterable{
    case workoutNumber, activity, activityType, equipment, seconds, rpe, tss
    case tssMethod, km, kj, ascentMetres, reps, isRace, cadence, watts
    case wattsEstimated, heartRate, isBrick, keywords, comments, lastSave
}

enum DayJSONProperty: String, CaseIterable{
    case iso8601DateString, type, comments
}

enum ReadingJSONProperty: String, CaseIterable{
    case type, value
}

enum RaceResultJSONProperty: String, CaseIterable{
    case raceNumber, type, brand, distance, name, category, overallPosition, categoryPosition
    case swimSeconds, t1Seconds, bikeSeconds, t2Seconds, runSeconds, swimKM, bikeKM, runKM
    case comments, raceReport, iso8601DateString, lastSave
}

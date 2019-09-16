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
    case wattsEstimated, heartRate, isBrick, keywords, comments
}

enum DayJSONProperty: String, CaseIterable{
    case iso8601DateString, type, comments
}

enum ReadingJSONProperty: String, CaseIterable{
    case type, value
}

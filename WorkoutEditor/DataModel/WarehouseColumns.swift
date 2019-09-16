//
//  WarehouseColumns.swift
//  WorkoutEditor
//
//  Created by Steven Lord on 12/09/2019.
//  Copyright © 2019 Steven Lord. All rights reserved.
//

import Foundation

enum WarehouseColumn: String, CaseIterable{
    
    case date, year, year_week, year_month, year_quarter, day_of_week, month, week, quarter
    case day_type, fatigue, motivation
    case sleep_seconds, sleep_minutes, sleep_hours, sleep_score, sleep_quality, sleep_quality_score
    case km, miles, tss, rpe, hr, watts, seconds, minutes, hours, ascent_metres, ascent_feet, kj, reps, is_race, brick, watts_estimated, cadence
    case rpe_tss, mph, kph, ctl, atl, tsb, rpe_ctl, rpe_atl, rpe_tsb, monotony, strain, rpe_monotony, rpe_strain, kg, lbs, fat_percentage, resting_hr
    case sdnn, rmssd, kg_recorded, lbs_recorded, fat_percentage_recorded, resting_hr_recorded, sdnn_recorded, rmssd_recorded
    case sdnn_off, sdnn_easy, sdnn_hard, rmssd_off, rmssd_easy, rmssd_hard

    func sqlType() -> String{
        switch self{
        case .date:
            return "date PRIMARY KEY"
        case .month, .day_of_week:
            return "varchar(8) NOT NULL"
        case .year, .year_week, .year_month, .day_type, .year_quarter, .week, .quarter:
            return "varchar(16) NOT NULL"
        case .sleep_quality:
            return "varchar(16) NOT NULL DEFAULT 'Average'"
        case .fatigue, .motivation, .sleep_hours, .km, .miles, .rpe, .hours, .mph, .kph, .ctl, .atl, .tsb, .rpe_ctl, .rpe_atl, .rpe_tsb,
             .monotony, .strain, .rpe_monotony, .rpe_strain, .kg, .lbs, .fat_percentage, .sdnn, .rmssd, .sleep_quality_score, .sleep_score,
             .sdnn_off, .sdnn_easy, .sdnn_hard, .rmssd_off, .rmssd_easy, .rmssd_hard:
            return "REAL DEFAULT 0.0 NOT NULL"
        case .sleep_minutes, .sleep_seconds, .tss, .rpe_tss, .hr, .watts, .seconds, .minutes, .ascent_feet, .ascent_metres, .kj, .reps,
             .cadence, .resting_hr:
            return "INTEGER DEFAULT 0 NOT NULL"
        case .is_race, .brick, .watts_estimated, .kg_recorded, .lbs_recorded, .fat_percentage_recorded, .resting_hr_recorded,
                 .sdnn_recorded, .rmssd_recorded:
            return "BOOLEAN DEFAULT 0 NOT NULL"
        }
    }
    
    static func dayColumns() -> [WarehouseColumn]{
        return [.date, .year, .year_week, .year_month, .year_quarter, .day_of_week, .week, .month, .quarter, .day_type, .fatigue, .motivation, .sleep_seconds, .sleep_minutes, .sleep_hours, .sleep_quality,
                .sleep_quality_score, .sleep_score, .km, .miles, .tss, .rpe, .hr, .watts, .seconds, .minutes, .hours, .ascent_metres, .ascent_feet, .kj, .reps, .is_race, .brick,
                .watts_estimated, .cadence, .rpe_tss, .mph, .kph, .ctl, .atl, .tsb, .rpe_ctl, .rpe_atl, .rpe_tsb, .monotony, .strain, .rpe_monotony, .rpe_strain, .kg, .lbs, .fat_percentage,
                .resting_hr, .sdnn, .rmssd, .kg_recorded, .lbs_recorded, .fat_percentage_recorded, .resting_hr_recorded, .sdnn_recorded, .rmssd_recorded,
                .sdnn_off, .sdnn_easy, .sdnn_hard, .rmssd_off, .rmssd_easy, .rmssd_hard]
    }

    static func interpolatedColumns() -> [WarehouseColumn]{
        return [.kg, .lbs, .fat_percentage, .resting_hr, .sdnn, .rmssd]
    }
    
    func recordedColumnName() -> String?{
        if WarehouseColumn.interpolatedColumns().contains(self){
            return "\(self.rawValue)_recorded"
        }else{
            return nil
        }
    }
    
    func value(forDay day: Day, workoutType type: WorkoutType) -> String{
        switch self{
        case .date: return "\"\(day.iso8601DateString)\""
        case .year_week: return "\"\(day.date.yearForWeekOfYear)-\(day.date.weekOfYear)\""
        case .week: return "\"\(day.date.weekOfYear)\""
        case .year: return "\"\(day.date.year)\""
        case .year_month: return "\"\(day.date.year)-\(day.date.monthAsStringShort)\""
        case .year_quarter: return "\"\(day.date.year)-\(day.date.quarter)\""
        case .day_of_week: return "\"\(day.date.dayNameShort)\""
        case .month: return "\"\(day.date.monthAsStringShort)\""
        case .quarter: return "\"\(day.date.quarter)\""
        case .day_type: return "\"\(day.type)\""
        case .sleep_quality: return "\"\(SleepQualityMapper().string(fromScore: day.reading(forType: "sleepQualityScore")?.value ?? 0.0))\""
        case .fatigue: return String(day.reading(forType: "fatigue")?.value ?? 0.0)
        case .motivation: return String(day.reading(forType: "motivation")?.value ?? 0.0)
        case .sleep_hours: return String(day.reading(forType: "sleep")?.value ?? 0.0)
        case .sleep_quality_score: return String(day.reading(forType: "sleepQualityScore")?.value ?? 0.0)
        case .sleep_score: return String((day.reading(forType: "sleep")?.value ?? 0.0) * (day.reading(forType: "sleepQualityScore")?.value ?? 0.0))
        case .km: return String(day.workoutsFor(type: type).reduce(0.0, {$0 + $1.km}))
        case .miles: return String(day.workoutsFor(type: type).reduce(0.0, {$0 + $1.miles}))
        case .rpe:
            let seconds: Double = Double(day.workoutsFor(type: type).reduce(0, {$0 + $1.seconds}))
            if seconds == 0.0{
                return "0.0"
            }else{
                let numerator: Double = day.workoutsFor(type: type).reduce(0.0, {$0 + $1.rpe * Double($1.seconds)})
                return String(numerator / seconds)
            }
        case .hours: return String(Double(day.workoutsFor(type: type).reduce(0, {$0 + $1.seconds})) / 3600.0)
        case .mph:
            let hours: Double = Double(day.workoutsFor(type: type).reduce(0, {$0 + $1.seconds})) / 3600.0
            if hours == 0.0{
                return "0.0"
            }else{
                return String(day.workoutsFor(type: type).reduce(0.0, {$0 + $1.miles}) / hours)
            }
        case .kph:
            let hours: Double = Double(day.workoutsFor(type: type).reduce(0, {$0 + $1.seconds})) / 3600.0
            if hours == 0.0{
                return "0.0"
            }else{
                return String(day.workoutsFor(type: type).reduce(0.0, {$0 + $1.km}) / hours)
            }
        case .kg:  return String(day.reading(forType: "kg")?.value ?? 0.0)
        case .lbs:  return String((day.reading(forType: "kg")?.value ?? 0.0) * 2.20462)
        case .fat_percentage: return String(day.reading(forType: "fatPercentage")?.value ?? 0.0)
        case .sdnn: return String(day.reading(forType: "SDNN")?.value ?? 0.0)
        case .rmssd: return String(day.reading(forType: "rMSSD")?.value ?? 0.0)
        case .sleep_seconds: return String(Int((day.reading(forType: "sleep")?.value ?? 0.0)*3600))
        case .sleep_minutes: return String(Int((day.reading(forType: "sleep")?.value ?? 0.0)*60))
        case .tss: return String(day.workoutsFor(type: type).reduce(0, {$0 + $1.tss}))
        case .hr:
            let seconds: Double = day.workoutsFor(type: type).reduce(0.0, {$0 + ($1.heartRate > 0 ? Double($1.seconds) : 0.0)})
            if seconds == 0.0{
                return "0"
            }else{
                let numerator: Double = day.workoutsFor(type: type).reduce(0.0, {$0 + ($1.heartRate > 0 ? Double($1.heartRate) * Double($1.seconds) : 0.0)})
                return String(Int(numerator / seconds))
            }
        case .watts:
            let seconds: Double = day.workoutsFor(type: type).reduce(0.0, {$0 + ($1.watts > 0 ? Double($1.seconds) : 0.0)})
            if seconds == 0.0{
                return "0"
            }else{
                let numerator: Double = day.workoutsFor(type: type).reduce(0.0, {$0 + ($1.watts > 0 ? Double($1.watts) * Double($1.seconds) : 0.0)})
                return String(Int(numerator / seconds))
            }
        case .seconds: return String(day.workoutsFor(type: type).reduce(0, {$0 + $1.seconds}))
        case .minutes: return String(Int(Double(day.workoutsFor(type: type).reduce(0, {$0 + $1.seconds})) / 60.0))
        case .ascent_metres:  return String(day.workoutsFor(type: type).reduce(0, {$0 + $1.ascentMetres}))
        case .ascent_feet: return String(day.workoutsFor(type: type).reduce(0, {$0 + $1.ascentFeet}))
        case .kj: return String(day.workoutsFor(type: type).reduce(0, {$0 + $1.kj}))
        case .reps: return String(day.workoutsFor(type: type).reduce(0, {$0 + $1.reps}))
        case .cadence:
            let seconds: Double = day.workoutsFor(type: type).reduce(0.0, {$0 + ($1.cadence > 0 ? Double($1.seconds) : 0.0)})
            if seconds == 0.0{
                return "0"
            }else{
                let numerator: Double = day.workoutsFor(type: type).reduce(0.0, {$0 + ($1.cadence > 0 ? Double($1.cadence) * Double($1.seconds) : 0.0)})
                return String(Int(numerator / seconds))
            }
            
        case .rpe_tss: return String(day.workoutsFor(type: type).reduce(0, {$0 + $1.rpeTSS}))
        case .resting_hr: return String(Int(day.reading(forType: "restingHR")?.value ?? 0.0))
        case .is_race: return day.workoutsFor(type: type).reduce(false, {$0 || $1.isRace}) ? "1" : "0"
        case .brick: return day.workoutsFor(type: type).reduce(false, {$0 || $1.isBrick}) ? "1" : "0"
        case .watts_estimated: return day.workoutsFor(type: type).reduce(false, {$0 || $1.wattsEstimated}) ? "1" : "0"
        case .kg_recorded, .lbs_recorded: return day.reading(forType: "kg") != nil ? "1" : "0"
        case .fat_percentage_recorded: return day.reading(forType: "fatPercentage") != nil ? "1" : "0"
        case .resting_hr_recorded: return day.reading(forType: "restingHR") != nil ? "1" : "0"
        case .sdnn_recorded: return day.reading(forType: "SDNN") != nil ? "1" : "0"
        case .rmssd_recorded: return day.reading(forType: "rMSSD") != nil ? "1" : "0"
        default: return "0.0"
        }
    }

    
}

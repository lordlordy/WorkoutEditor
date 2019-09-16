//
//  SleepQualityMapper.swift
//  WorkoutEditor
//
//  Created by Steven Lord on 12/09/2019.
//  Copyright © 2019 Steven Lord. All rights reserved.
//

import Foundation

class SleepQualityMapper{
 
    private let vPoor: Double = 0.2
    private let poor: Double = 0.4
    private let average: Double = 0.6
    private let good: Double = 0.8
    private let excellent: Double = 1.0
    
    func string(fromScore score: Double) -> String{
        if score <= vPoor{
            return "Very Poor"
        }else if score <= poor{
            return "Poor"
        }else if score <= average{
            return "Average"
        }else if score <= good{
            return "Good"
        }else{
            return "Excellent"
        }
    }
    
    func score(fromQuality quality: String) -> Double{
        switch quality{
        case "Excellent": return excellent
        case "Good": return good
        case "Average": return average
        case "Poor": return poor
        case "Very Poor": return vPoor
        default: return 0.0
        }
    }
}

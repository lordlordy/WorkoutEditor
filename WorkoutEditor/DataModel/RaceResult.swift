//
//  RaceResult.swift
//  WorkoutEditor
//
//  Created by Steven Lord on 16/09/2019.
//  Copyright © 2019 Steven Lord. All rights reserved.
//

import Foundation

@objc class RaceResult: NSObject{
    
    @objc var primaryKey: String { return "\(iso8601DateString)-\(String(raceNumber))" }
    @objc var date: Date
    @objc var raceNumber: Int
    @objc var type: String
    @objc var brand: String
    @objc var distance: String
    @objc var name: String
    @objc var category: String
    @objc var overallPosition: Int
    @objc var categoryPosition: Int
    @objc var swimSeconds: Int
    @objc var t1Seconds: Int
    @objc var bikeSeconds: Int
    @objc var t2Seconds: Int
    @objc var runSeconds: Int
    @objc var swimKM: Double
    @objc var bikeKM: Double
    @objc var runKM: Double
    @objc var comments: String
    @objc var raceReport: String
    @objc var lastSave: Date? = nil
    
    @objc var totalKM: Double { return swimKM + bikeKM + runKM}
    @objc var totalSeconds: Int { return swimSeconds +  t1Seconds + bikeSeconds + t2Seconds + runSeconds}
    
    @objc var iso8601DateString: String{
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df.string(from: date)
    }
    
    @objc var raceReportTitleString: String{
        return "Race Report: \(iso8601DateString): \(name)"
    }
    
    @objc override var description: String{
        return "\(iso8601DateString): \(name)"
    }
    
    convenience override init(){
        self.init(date: Date(), raceNumber: 1, type: "SwimRun", brand: "OtillO", distance: "Sprint", name: "", category: "", overallPosition: 0, categoryPosition: 0, swimSeconds: 0, t1Seconds: 0, bikeSeconds: 0, t2Seconds: 0, runSeconds: 0, swimKM: 0.0, bikeKM: 0.0, runKM: 0.0, comments: "", raceReport: "")
    }
    
    init(date: Date, raceNumber: Int, type: String, brand: String, distance: String, name: String, category: String, overallPosition: Int, categoryPosition: Int, swimSeconds: Int, t1Seconds: Int, bikeSeconds: Int, t2Seconds: Int, runSeconds: Int, swimKM: Double, bikeKM: Double, runKM: Double, comments: String, raceReport: String){

        self.date = date
        self.raceNumber = raceNumber
        self.type = type
        self.brand = brand
        self.distance = distance
        self.name = name
        self.category = category
        self.overallPosition = overallPosition
        self.categoryPosition = categoryPosition
        self.swimSeconds = swimSeconds
        self.t1Seconds = t1Seconds
        self.bikeSeconds = bikeSeconds
        self.t2Seconds = t2Seconds
        self.runSeconds = runSeconds
        self.swimKM = swimKM
        self.bikeKM = bikeKM
        self.runKM = runKM
        self.comments = comments
        self.raceReport = raceReport
        
        super.init()
    }
    
}

extension RaceResult{
    
    override public class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String>{
        let keyPaths = super.keyPathsForValuesAffectingValue(forKey: key)
        switch key {
        case "totalSeconds":
            return keyPaths.union(Set(["swimSeconds", "t1Seconds", "bikeSeconds", "t2Seconds", "runSeconds"]))
        case "totalKM":
            return keyPaths.union(Set(["swimKM", "bikeKM", "runKM"]))
        case "summaryString":
                return keyPaths.union(Set(["date", "name"]))
        default:
            return keyPaths
        }
    }
}

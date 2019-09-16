//
//  TrainingDiary.swift
//  WorkoutEditor
//
//  Created by Steven Lord on 10/09/2019.
//  Copyright © 2019 Steven Lord. All rights reserved.
//

import Foundation

class TrainingDiary: NSObject{
    
    @objc var swimKM: Double{
        return dayCache.values.reduce(0.0, {$0 + $1.swimKM})
    }
    @objc var bikeKM: Double{
        return dayCache.values.reduce(0.0, {$0 + $1.bikeKM})
    }
    @objc var runKM: Double{
        return dayCache.values.reduce(0.0, {$0 + $1.runKM})
    }
    @objc var totalHours: Double{
        return dayCache.values.reduce(0.0, {$0 + $1.totalHours})
    }
    
    @objc var dayTypes: [String]{ return WorkoutDBAccess.shared.dayTypes() }
    @objc var readingTypes: Set<String>{ return WorkoutDBAccess.shared.readingTypes() }
    @objc var readingTypesArray: [String]{ return Array(readingTypes).sorted() }
    @objc var activities: [String] { return WorkoutDBAccess.shared.activities()}
    @objc var activityTypes: [String] { return WorkoutDBAccess.shared.activityTypes()}
    @objc var equipmentTypes: [String] { return WorkoutDBAccess.shared.equipmentTypes()}
    @objc var tssMethods: [String] { return WorkoutDBAccess.shared.tssMethods()}

    private var dayCache: [String:Day] = [:]
    private var monthlyNodes: [PeriodNode]?
    private var weeklyNodes: [PeriodNode]?
    var monthly: Bool = true
    
    private var df: DateFormatter{
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter
    }

    func setNodesForRebuild(){
        monthlyNodes = nil
        weeklyNodes = nil
    }
    
    func day(forDate d: Date) -> Day?{
        return dayCache[df.string(from: d)]
    }
    
    // returns true if can add day
    func add(day d: Day) -> Bool{
        let dStr: String = df.string(from: d.date)
        if dayCache[dStr] == nil{
            dayCache[dStr] = d
            return true
        }
        return false
    }
    
    // TO DO - change this to throws and handle not saving
    func save(day d: Day){
        WorkoutDBAccess.shared.save(day: d)
        d.unsavedChanges = false
        for w in d.workouts{
            w.unsavedChanges = false
        }
    }
    
    func setReload(){
        monthlyNodes = nil
        weeklyNodes = nil
    }

    func ascendingOrderedDays() -> [Day]{
        return dayCache.values.sorted(by: {$0.date < $1.date})
    }
    
    func descendingOrderedDays() -> [Day]{
        return dayCache.values.sorted(by: {$0.date > $1.date})
    }
    
    func getNodes() -> [PeriodNode]{
        return monthly ? getMonthlyNodes() : getWeeklyNodes()
    }
    
    func getMonthlyNodes() -> [PeriodNode]{
        if monthlyNodes == nil {
            monthlyNodes = createMonthlyNodes()
        }
        return monthlyNodes!
    }
    
    func getWeeklyNodes() -> [PeriodNode]{
        if weeklyNodes == nil{
            weeklyNodes = createWeeklyNodes()
        }
        return weeklyNodes!
    }
    
    func defaultNewDay() -> Day{
        let days: [Day] = descendingOrderedDays()
        var newDate: Date = Date()
        if days.count > 0{
            newDate = Calendar.current.date(byAdding: DateComponents(day: 1), to: days[0].date)!
        }
        let day: Day = Day(date: newDate, type: "Normal", comments: "", trainingDiary: self)
        day.add(readings: [
            Reading(type: "sleep", value: 8.0, parent: day),
            Reading(type: "sleepQuality", value: 0.75, parent: day),
            Reading(type: "motivation", value: 5.0, parent: day),
            Reading(type: "fatigue", value: 5.0, parent: day)])
        add(day: day)
        return day
    }
    
}

extension TrainingDiary: PeriodNode{
    var name: String { return "Training Diary" }
    var children: [PeriodNode] { return getNodes() }
    var childCount: Int { return children.count }
    var totalKM: Double { return children.reduce(0.0, {$0 + $1.totalKM}) }
    var totalSeconds: TimeInterval { return children.reduce(0.0, {$0 + $1.totalSeconds}) }
    var totalTSS: Int { return children.reduce(0, {$0 + $1.totalTSS}) }
    var swimSeconds: TimeInterval { return children.reduce(0.0, {$0 + $1.swimSeconds}) }
    var swimTSS: Int { return children.reduce(0, {$0 + $1.swimTSS}) }
    var bikeSeconds: TimeInterval { return children.reduce(0.0, {$0 + $1.bikeSeconds}) }
    var bikeTSS: Int { return children.reduce(0, {$0 + $1.bikeTSS}) }
    var runSeconds: TimeInterval { return children.reduce(0.0, {$0 + $1.runSeconds}) }
    var runTSS: Int { return children.reduce(0, {$0 + $1.runTSS}) }
    var fromDate: Date { return dayCache.values.map({$0.date}).min() ?? Date() }
    var toDate: Date { return dayCache.values.map({$0.date}).max() ?? Date() }
    var isLeaf: Bool { return false}
    var leafCount: Int { return children.reduce(0, {$0 + $1.leafCount}) }
    var type: String { return "Diary" }
    
    @objc var sleep: Double {
        return children.count > 0 ? children.reduce(0.0, {$0 + $1.sleep}) / Double(children.count) : 0.0
    }
    @objc var sleepQualityScore: Double {
        return children.count > 0 ? children.reduce(0.0, {$0 + $1.sleepQualityScore}) / Double(children.count) : 0.0
    }
    @objc var motivation: Double {
        return children.count > 0 ? children.reduce(0.0, {$0 + $1.motivation}) / Double(children.count) : 0.0
    }
    @objc var fatigue: Double {
        return children.count > 0 ? children.reduce(0.0, {$0 + $1.fatigue}) / Double(children.count) : 0.0
    }
    @objc var kg: Double {
        let numerator: Double = children.reduce(0.0, {$0 + $1.kg})
        let denominator: Double = children.reduce(0.0, {$0 + ($1.kg > 0 ? 1.0 : 0.0)})
        return denominator > 0 ? numerator/denominator : 0.0
    }
    @objc var fatPercentage: Double {
        let numerator: Double = children.reduce(0.0, {$0 + $1.fatPercentage})
        let denominator: Double = children.reduce(0.0, {$0 + ($1.fatPercentage > 0 ? 1.0 : 0.0)})
        return denominator > 0 ? numerator/denominator : 0.0
    }
    @objc var restingHR: Int {
        let numerator: Int = children.reduce(0, {$0 + $1.restingHR})
        let denominator: Double = children.reduce(0.0, {$0 + ($1.restingHR > 0 ? 1.0 : 0.0)})
        return denominator > 0 ? Int(Double(numerator)/denominator) : 0
    }
    @objc var sdnn: Double {
        let numerator: Double = children.reduce(0.0, {$0 + $1.sdnn})
        let denominator: Double = children.reduce(0.0, {$0 + ($1.sdnn > 0 ? 1.0 : 0.0)})
        return denominator > 0 ? numerator/denominator : 0.0
    }
    @objc var rMSSD: Double {
        let numerator: Double = children.reduce(0.0, {$0 + $1.rMSSD})
        let denominator: Double = children.reduce(0.0, {$0 + ($1.rMSSD > 0 ? 1.0 : 0.0)})
        return denominator > 0 ? numerator/denominator : 0.0
    }
    
    @objc var unsavedChanges: Bool{
        return children.reduce(false, {$0 || $1.unsavedChanges})
    }
    
    @objc var days: Set<Day>{
        var result: Set<Day> = Set()
        for c in children{
            result = result.union(c.days)
        }
        return result
    }
    
}


// extension to create period nodes
extension TrainingDiary{
    
    private func createMonthlyNodes() -> [PeriodNode]{
        var monthYearNodes: [PeriodNodeImplementation] = []
        var yearNodes: [String: PeriodNodeImplementation] = [:]
        for d in descendingOrderedDays(){
            let year: String = String(d.date.year)
            let month: String = d.date.monthAsString
            let quarter: String = "Q\(d.date.quarter)"
            var yearNode: PeriodNodeImplementation
            var monthNode: PeriodNodeImplementation
            var quarterNode: PeriodNodeImplementation
            
            if let yNode = yearNodes[year]{
                yearNode = yNode
            }else{
                yearNode = PeriodNodeImplementation(name: year, from: d.date.startOfYear, to: d.date.endOfYear, type: "Year")
                monthYearNodes.append(yearNode)
                yearNodes[year] = yearNode
            }
            
            if let qNode = yearNode.child(forName: quarter){
                quarterNode = qNode
            }else{
                quarterNode = PeriodNodeImplementation(name: quarter, from: Date(), to: Date(), type: "Quarter")
                yearNode.add(child: quarterNode)
            }
            
            if let mNode = quarterNode.child(forName: month){
                monthNode = mNode
            }else{
                monthNode = PeriodNodeImplementation(name: d.date.monthAsString, from: d.date.startOfMonth, to: d.date.endOfMonth, type: "Month")
                quarterNode.add(child: monthNode)
            }
            monthNode.add(child: d)
        }
        return monthYearNodes
    }
    
    private func createWeeklyNodes() -> [PeriodNode]{
        var weekYearNodes: [PeriodNodeImplementation] = []
        var yearNodes: [String: PeriodNodeImplementation] = [:]
        for d in descendingOrderedDays(){
            let year: String = String(d.date.yearForWeekOfYear)
            let week: String = "Wk-\(d.date.weekOfYear)"
            var yearNode: PeriodNodeImplementation
            var weekNode: PeriodNodeImplementation
            
            if let yNode = yearNodes[year]{
                yearNode = yNode
            }else{
                yearNode = PeriodNodeImplementation(name: year, from: d.date.startOfYear, to: d.date.endOfYear, type: "Year")
                weekYearNodes.append(yearNode)
                yearNodes[year] = yearNode
            }
            
            if let wNode = yearNode.child(forName: week){
                weekNode = wNode
            }else{
                weekNode = PeriodNodeImplementation(name: week, from: d.date.startOfWeek, to: d.date.endOfWeek, type: "Week")
                yearNode.add(child: weekNode)
            }
            weekNode.add(child: d)
        }
        return weekYearNodes
    }
    
    
    private class PeriodNodeImplementation: NSObject, PeriodNode{
        
        private var from: Date
        private var to: Date
        private var periodName: String
        private var childPeriods: [PeriodNode] = []
        
        init(name n: String, from: Date, to: Date, type: String){
            periodName = n
            self.from = from
            self.to = to
            self.type = type
        }
        
        var type: String
        @objc var name: String { return periodName }
        @objc var children: [PeriodNode] { return childPeriods }
        @objc var childCount: Int { return children.count }
        
        func add(child: PeriodNode) { childPeriods.append(child) }
        
        @objc var totalKM: Double { return children.reduce(0.0, {$0 + $1.totalKM}) }
        @objc var totalSeconds: Double { return TimeInterval(children.reduce(0.0, {$0 + $1.totalSeconds})) }
        @objc var totalTSS: Int { return children.reduce(0, {$0 + $1.totalTSS}) }
        @objc var swimKM: Double { return children.reduce(0.0, {$0 + $1.swimKM}) }
        @objc var swimSeconds: Double { return children.reduce(0.0, {$0 + $1.swimSeconds}) }
        @objc var swimTSS: Int { return children.reduce(0, {$0 + $1.swimTSS}) }
        @objc var bikeKM: Double { return children.reduce(0.0, {$0 + $1.bikeKM}) }
        @objc var bikeSeconds: Double { return children.reduce(0.0, {$0 + $1.bikeSeconds}) }
        @objc var bikeTSS: Int { return children.reduce(0, {$0 + $1.bikeTSS}) }
        @objc var runKM: Double { return children.reduce(0.0, {$0 + $1.runKM}) }
        @objc var runSeconds: Double { return children.reduce(0.0, {$0 + $1.runSeconds}) }
        @objc var runTSS: Int { return children.reduce(0, {$0 + $1.runTSS}) }
        @objc var fromDate: Date {
            let childFromDate = children.map({$0.fromDate}).sorted(by: {$0 < $1})
            if childFromDate.count > 0{
                return childFromDate[0]
            }
            return Date()
        }
        @objc var toDate: Date {
            let childToDate = children.map({$0.toDate}).sorted(by: {$0 > $1})
            if childToDate.count > 0{
                return childToDate[0]
            }
            return Date()
        }
        @objc var isLeaf: Bool { return children.count == 0}
        
        @objc var leafCount: Int {
            if isLeaf{
                return 1
            }else{
                var count = 0
                for c in children{
                    count += c.leafCount
                }
                return count
            }
        }
        
        func inPeriod(_ p: PeriodNode) -> Bool{
            return (p.fromDate <= from) && (p.toDate >= to)
        }
        
        func child(forName n: String) -> PeriodNodeImplementation?{
            for node in childPeriods{
                if node.name == n{
                    return node as? PeriodNodeImplementation
                }
            }
            return nil
        }
        
        @objc var sleep: Double {
            return children.count > 0 ? children.reduce(0.0, {$0 + $1.sleep}) / Double(children.count) : 0.0
        }
        @objc var sleepQualityScore: Double {
            return children.count > 0 ? children.reduce(0.0, {$0 + $1.sleepQualityScore}) / Double(children.count) : 0.0
        }
        @objc var motivation: Double {
            return children.count > 0 ? children.reduce(0.0, {$0 + $1.motivation}) / Double(children.count) : 0.0
        }
        @objc var fatigue: Double {
            return children.count > 0 ? children.reduce(0.0, {$0 + $1.fatigue}) / Double(children.count) : 0.0
        }
        @objc var kg: Double {
            let numerator: Double = children.reduce(0.0, {$0 + $1.kg})
            let denominator: Double = children.reduce(0.0, {$0 + ($1.kg > 0 ? 1.0 : 0.0)})
            return denominator > 0 ? numerator/denominator : 0.0
        }
        @objc var fatPercentage: Double {
            let numerator: Double = children.reduce(0.0, {$0 + $1.fatPercentage})
            let denominator: Double = children.reduce(0.0, {$0 + ($1.fatPercentage > 0 ? 1.0 : 0.0)})
            return denominator > 0 ? numerator/denominator : 0.0
        }
        @objc var restingHR: Int {
            let numerator: Int = children.reduce(0, {$0 + $1.restingHR})
            let denominator: Double = children.reduce(0.0, {$0 + ($1.restingHR > 0 ? 1.0 : 0.0)})
            return denominator > 0 ? Int(Double(numerator)/denominator) : 0
        }
        @objc var sdnn: Double {
            let numerator: Double = children.reduce(0.0, {$0 + $1.sdnn})
            let denominator: Double = children.reduce(0.0, {$0 + ($1.sdnn > 0 ? 1.0 : 0.0)})
            return denominator > 0 ? numerator/denominator : 0.0
        }
        @objc var rMSSD: Double {
            let numerator: Double = children.reduce(0.0, {$0 + $1.rMSSD})
            let denominator: Double = children.reduce(0.0, {$0 + ($1.rMSSD > 0 ? 1.0 : 0.0)})
            return denominator > 0 ? numerator/denominator : 0.0
        }
        
        @objc var unsavedChanges: Bool{
            return children.reduce(false, {$0 || $1.unsavedChanges})
        }
        
        @objc var days: Set<Day>{
            var result: Set<Day> = Set()
            for c in children{
                result = result.union(c.days)
            }
            return result
        }
    }

}

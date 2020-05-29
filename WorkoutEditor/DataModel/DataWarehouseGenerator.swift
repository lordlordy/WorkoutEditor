//
//  DataWarehouseGenerator.swift
//  WorkoutEditor
//
//  Created by Steven Lord on 12/09/2019.
//  Copyright © 2019 Steven Lord. All rights reserved.
//

import Foundation
import SQLite3

let monotonyDays: Int = 7

class DataWarehouseGenerator{
    
    private var trainingDiary: TrainingDiary
    private var dbURL: URL
    private var database: OpaquePointer?
    private var tableColumns: String
    private var timeFormatter: DateComponentsFormatter = DateComponentsFormatter()
    private var dateFormatter: DateFormatter = DateFormatter()
    private var ctlFactor: Double
    private var ctlDecay: Double
    private var atlFactor: Double
    private var atlDecay: Double
    
    init(trainingDiary td: TrainingDiary, dbURL url: URL){
        trainingDiary = td
        dbURL = url
        timeFormatter.allowedUnits = [.hour, .minute, .second]
        timeFormatter.unitsStyle = .positional
        timeFormatter.zeroFormattingBehavior = .pad
        
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        var cols: [String] = []
        for col in WarehouseColumn.dayColumns(){ cols.append(col.rawValue) }
        tableColumns = cols.joined(separator: ",")

        ctlDecay = exp(-1/42)
        ctlFactor = 1 - ctlDecay
        atlDecay = exp(-1/7)
        atlFactor = 1 - atlDecay

    }
    
    func populateTrainingDiaryWithTSB(fromDate date: String?=nil){
        
        let allData = tsb(fromTable: "day_All_All_All", fromDate: date)
        let swimData = tsb(fromTable: "day_Swim_All_All", fromDate: date)
        let bikeData = tsb(fromTable: "day_Bike_All_All", fromDate: date)
        let runData = tsb(fromTable: "day_Run_All_All", fromDate: date)
        
        var days: [Day] = [Day](trainingDiary.dayCache.values)
        if let d = date{
            days = days.filter({$0.iso8601DateString >= d})
        }
        
        for d in days{
            let total: (ctl: Double, atl: Double) = allData[d.iso8601DateString] ?? (0.0, 0.0)
            let swim: (ctl: Double, atl: Double) = swimData[d.iso8601DateString] ?? (0.0, 0.0)
            let bike: (ctl: Double, atl: Double) = bikeData[d.iso8601DateString] ?? (0.0, 0.0)
            let run: (ctl: Double, atl: Double) = runData[d.iso8601DateString] ?? (0.0, 0.0)
            d.ctl = total.ctl
            d.atl = total.atl
            d.ctlSwim = swim.ctl
            d.atlSwim = swim.atl
            d.ctlBike = bike.ctl
            d.atlBike = bike.atl
            d.ctlRun = run.ctl
            d.atlRun = run.atl
        }
    }
    
    func latestDateString() -> String{
        guard let db = db() else{
            print("unable to calculate HRV thresholds as no DB connection")
            return ""
        }

        let dateQueryStr: String = "SELECT max(date) FROM day_All_All_All"
        var query: OpaquePointer? = nil
        var str: String = ""
        if sqlite3_prepare_v2(db, dateQueryStr, -1, &query, nil) == SQLITE_OK{
            if sqlite3_step(query) == SQLITE_ROW{
                str = String(cString: sqlite3_column_text(query, 0))
            }
        }
        sqlite3_finalize(query)
        return str
    }

    func generate(progressUpdater updater: ((Double, String) -> Void)?){
        generate(fromDate: nil, progressUpdater: updater)
    }
    
    func update(progressUpdater updater: ((Double, String) -> Void)?){
        guard let lastDate = dateFormatter.date(from: latestDateString()) else {
            if let progress = updater{
                progress(1.0, "Cannot update as unable to generate last date in the Data Warehouse")
            }
            print("update failed due to not finding the last date in the date warehouse. gutted!")
            return
        }
        
        //update from the next day
        generate(fromDate: lastDate.tomorrow(), progressUpdater: updater)
        let df: DateFormatter = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        populateTrainingDiaryWithTSB(fromDate: df.string(from: lastDate.tomorrow()))
    }
    
    func rebuild(fromDate date: Date, progressUpdater updater: ((Double, String) -> Void)?){
        // delete all entries from this date and then generate
        
        let tableArray = tables()
        let denominator: Double = Double(tableArray.count)
        var count: Double = 0.0
        for table in tableArray{
            count += 1.0
            if let progress = updater{
                progress(count/denominator, "Deleting from \(table.tableName) on and after \(date)")
            }
            let sql: String = "DELETE FROM \(table.tableName) WHERE date>='\(dateFormatter.string(from: date))'"
            let _: Bool = execute(sql: sql)
        }
        generate(fromDate: date, progressUpdater: updater)
        let df: DateFormatter = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        populateTrainingDiaryWithTSB(fromDate: df.string(from: date))
    }
    
    private func generate(fromDate date: Date?, progressUpdater updater: ((Double, String) -> Void)?){
        let start: Date = Date()
        var count: Double = 0.0
        var tables: [String:WorkoutType] = tablesDictionary()
        let days: [Day] = trainingDiary.ascendingOrderedDays(fromDate: date)
        var denominator: Double = Double(days.count)
        
        // days data
        for d in days{
            count += 1.0
            for t in d.workoutTypes{
                let t_name: String = "day_\(t.name)"
                if tables[t_name] == nil{
                    tables[t_name] = t
                    createTable(tableName: t_name, forWorkoutType: t, firstDate: d.iso8601DateString)
                    // add two as will cycle through all table for each of TSB calc and interpolation of values
                    denominator += 2
                }
            }
            for (key, value) in tables{
                insertRow(inTable: key, forType: value, andDay: d)
            }
            if let progress = updater{
                let info: String = "Day: \(WarehouseColumn.date.value(forDay: d, workoutType: WorkoutType(activity: nil, activityType: nil, equipment: nil))) T:\(tables.count)"
                progress(count / denominator, "Saving data: \(progressString(percentage: count / denominator, start: start, info: info))")
            }
        }

        // calculate TSB, Monotony & Strain
        var tCount: Int = 0
        for t in tables{
            count += 1
            tCount += 1
            insertTSBMonotonyAndStrain(forTable: t.key, fromDate: date)
            if let progress = updater{
                progress(count / denominator, "Calculating: \(progressString(percentage: count / denominator, start: start, info: "TSB, Monotony & Strain: \(t.key) (\(tCount) of \(tables.count)"))")
            }
        }

        // interpolate values
        tCount = 0
        for t in tables{
            count += 1
            tCount += 1
            interpolateValuesFor(table: t.key, fromDate: date)
            if let progress = updater{
                progress(count / denominator, "Interpolating: \(progressString(percentage: count / denominator, start: start, info: "\(t.key) (\(tCount) of \(tables.count)"))")
            }
        }
        
        if let progress = updater{
            progress(99.9, "HRV Thresholds...")
        }
        // this needs to be done AFTER interpolation
        populateHRVThresholds(fromDate: date)
        if let progress = updater{
            progress(100.0, "DONE! \(progressString(percentage: 1.0, start: start, info: ""))")
        }
        
        print("Time: \(Date().timeIntervalSince(start))")
    }
    
    
    func createDB(){
        createTablesTable()
    }
    
    private func populateHRVThresholds(fromDate date: Date?){
        guard let db = db() else{
            print("unable to calculate HRV thresholds as no DB connection")
            return
        }

        let hrvQuery: String = "SELECT date, sdnn, rmssd FROM day_All_All_All ORDER BY date ASC"
        var query: OpaquePointer? = nil
        var hrvData: [(dString: String, sdnn: Double, rmssd: Double)] = []
        var foundFirstNonZero: Bool = false
        if sqlite3_prepare_v2(db, hrvQuery, -1, &query, nil) == SQLITE_OK{
            while sqlite3_step(query) == SQLITE_ROW{
                let dString: String = String(cString: sqlite3_column_text(query, 0))
                let sdnn: Double = sqlite3_column_double(query, 1)
                let rmssd: Double = sqlite3_column_double(query, 2)
                if sdnn > 0 || rmssd > 0{ foundFirstNonZero = true}
                if foundFirstNonZero{
                    hrvData.append((dString, sdnn, rmssd))
                }
            }
        }
        sqlite3_finalize(query)
        
        if let d = date{
            // only need HRV data from HRV days prior to this date
            let firstDate: Date = Calendar.current.date(byAdding: DateComponents(day: -Maths.hrvThresholdDays), to: d)!
            hrvData = hrvData.filter({$0.dString >= dateFormatter.string(from: firstDate)})
        }
        
        let thresholds: [Maths.HRVThresholds] = Maths().hrvThresholds(orderedValues: hrvData)
        
        for t in tables(){
            var saveFromDate: String = t.firstDate
            if let d = date{
                let dString = dateFormatter.string(from: d)
                if dString > saveFromDate{
                    saveFromDate = dString
                }
            }
            let hData = thresholds.filter({$0.dString >= saveFromDate})
            var dateSetValuesDict: [String: String] = [:]
            for hrv in hData{
                dateSetValuesDict[hrv.dString] = """
                sdnn_off=\(hrv.sdnnOff), sdnn_easy=\(hrv.sdnnEasy), sdnn_hard=\(hrv.sdnnHard), sdnn_mean=\(hrv.sdnnMean), sdnn_std_dev=\(hrv.sdnnStdDev),
                rmssd_off=\(hrv.rmssdOff), rmssd_easy=\(hrv.rmssdEasy), rmssd_hard=\(hrv.rmssdHard), rmssd_mean=\(hrv.rmssdMean), rmssd_std_dev=\(hrv.rmssdStdDev)
                """
            }
            performTransaction(db, dateSetValuesDict, t.tableName)
            
        }
    }
    
    private func interpolateValuesFor(table t: String, fromDate date: Date?){
        
        guard let db = db() else {
            print("No db connection")
            return
        }
        
        for column in WarehouseColumn.interpolatedColumns(){
            guard let recordedColumn = column.recordedColumnName() else{
                print("No recorded column for \(column) so cannot interpolate")
                continue
            }
            var valuesSQL: String = """
            SELECT date, \(column.rawValue), \(recordedColumn) FROM \(t) ORDER BY date ASC
            """
            if let d = date{
                if let lastRecording = lastRecordedDate(forTable: t, onOrBeforeDate: d, recordedColumn: recordedColumn){
                    valuesSQL = """
                    SELECT date, \(column.rawValue), \(recordedColumn) FROM \(t)
                    WHERE date>='\(dateFormatter.string(from: lastRecording))'
                    ORDER BY date ASC
                    """
                }
            }
            var query: OpaquePointer? = nil
            var values: [(dString: String, value: Double)] = []
            if sqlite3_prepare_v2(db, valuesSQL, -1, &query, nil) == SQLITE_OK{
                while sqlite3_step(query) == SQLITE_ROW{
                    let dString: String = String(cString: sqlite3_column_text(query,0))
                    let recorded: Bool = sqlite3_column_int(query, 2) > 0
                    let value: Double = recorded ? sqlite3_column_double(query, 1) : 0.0
                    values.append((dString, value))
                }
            }
            sqlite3_finalize(query)
            let maths: Maths = Maths()
            let interpolatedValues: [(index: Int, value: Double)] = maths.interpolateZeros(values: values.map({$0.1}))
            
            var dateSetValuesDict: [String: String] = [:]
            for iv in interpolatedValues{
                dateSetValuesDict[values[iv.index].dString] = "\(column.rawValue)=\(iv.value)"
            }
            performTransaction(db, dateSetValuesDict, t)

        }
    }
    
    private func lastRecordedDate(forTable table: String, onOrBeforeDate date: Date, recordedColumn: String) -> Date?{
        guard let db = db() else {
            print("Unable to connect to db")
            return nil
        }
        var d: Date?
        let sql = """
        SELECT date FROM \(table)
        WHERE date<='\(dateFormatter.string(from: date))' AND \(recordedColumn)=1
        ORDER BY date DESC
        LIMIT 1
        """
        var query: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, sql, -1, &query, nil) == SQLITE_OK{
            if sqlite3_step(query) == SQLITE_ROW{
                let dString: String  = String(cString: sqlite3_column_text(query, 0))
                d = dateFormatter.date(from: dString)
            }
        }
        sqlite3_finalize(query)
        return d
    }
        
    fileprivate func performTransaction(_ db: OpaquePointer, _ dateSetValuesDict: [String : String], _ table: String) {
        let _: Bool = execute(sql: "BEGIN TRANSACTION")
        
        for (key, value) in dateSetValuesDict{
            let sql: String = """
            UPDATE \(table)
            SET \(value)
            WHERE date='\(key)'
            """
            let _: Bool = execute(sql: sql)
        }
        
        let _: Bool = execute(sql: "COMMIT")
    }
    
    private func insertTSBMonotonyAndStrain(forTable table: String, fromDate date: Date?){
        
        print("TSB, Monotony & Strain for \(table)")
        guard let db = db() else {
            print("No DB connection")
            return
        }
        
        var sql: String = "SELECT date, tss, rpe_tss FROM \(table) order by date ASC"
        if let d = date{
            sql = "SELECT date, tss, rpe_tss FROM \(table) WHERE date>='\(dateFormatter.string(from: d))' order by date ASC"
        }
        
        var tssData: [(dString: String, tss: Double, rpe_tss: Double)] = []
        var query: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, sql, -1, &query, nil) == SQLITE_OK{
            while sqlite3_step(query) == SQLITE_ROW{
                let dString: String  = String(cString: sqlite3_column_text(query, 0))
                let tss: Double = sqlite3_column_double(query, 1)
                let rpe_tss: Double = sqlite3_column_double(query, 2)
                tssData.append((dString, tss, rpe_tss))
            }
        }
        sqlite3_finalize(query)
    
        let initialValues = initialTSBValues(forDate: date, andTable: table)
        
        var ctl: Double = initialValues.ctl
        var atl: Double = initialValues.atl
        var rpeCTL: Double = initialValues.rpeCTL
        var rpeATL: Double = initialValues.rpeATL
        var setStrings: [String:String] = [:]
        let q: RollingSumQueue = RollingSumQueue(size: monotonyDays)
        let rpeQ: RollingSumQueue = RollingSumQueue(size: monotonyDays)
        
        if let d = date{
            // need to pre-load the queues
            let startDate: Date = Calendar.current.date(byAdding: DateComponents(day: -monotonyDays), to: d.yesterday())!
            let fromDate: String = dateFormatter.string(from: startDate)
            let toDate: String = dateFormatter.string(from: d.yesterday())
            
            sql = """
            SELECT tss, rpe_tss FROM \(table)
            WHERE date<='\(toDate)' and date>='\(fromDate)'
            ORDER BY date ASC
            """
            query = nil
            if sqlite3_prepare_v2(db, sql, -1, &query, nil) == SQLITE_OK{
                while sqlite3_step(query) == SQLITE_ROW{
                    let tss: Double = sqlite3_column_double(query, 0)
                    let rpe_tss: Double = sqlite3_column_double(query, 1)
                    _ = q.addAndReturnSum(value: tss)
                    _ = rpeQ.addAndReturnSum(value: rpe_tss)
                }
            }
            sqlite3_finalize(query)
        }
        
        for t in tssData{
            setStrings[t.dString] = ""
        }
        let maths: Maths = Maths()

        for d in tssData{
            ctl = d.tss * ctlFactor + ctl * ctlDecay
            atl = d.tss * atlFactor + atl * atlDecay
            rpeCTL = d.rpe_tss * ctlFactor + rpeCTL * ctlDecay
            rpeATL = d.rpe_tss * atlFactor + rpeATL * atlDecay
            
            _ = q.addAndReturnSum(value: d.tss)
            _ = rpeQ.addAndReturnSum(value: d.rpe_tss)
            let mon = maths.monotonyAndStrain(q.array())
            let rpeMON = maths.monotonyAndStrain(rpeQ.array())

            
            setStrings[d.dString] = """
            ctl=\(ctl), atl=\(atl), tsb=\(ctl-atl), rpe_ctl=\(rpeCTL), rpe_atl=\(rpeATL), rpe_tsb=\(rpeCTL-rpeATL),
            monotony=\(mon.monotony), strain=\(mon.strain), rpe_monotony=\(rpeMON.monotony), rpe_strain=\(rpeMON.strain)
            """
        }
        performTransaction(db, setStrings, table)
            
    }
    
    private func initialTSBValues(forDate date: Date?, andTable table: String) -> (atl: Double, ctl: Double, rpeATL: Double, rpeCTL: Double){
        var atl: Double = 0.0
        var ctl: Double = 0.0
        var rpeATL: Double = 0.0
        var rpeCTL: Double = 0.0
        if let d = date{
            // get values from date before
            let yesterday: String  = dateFormatter.string(from: d.yesterday())
            let sql = """
                SELECT atl, ctl, rpe_atl, rpe_ctl
                FROM \(table)
                WHERE date="\(yesterday)"
                """
            if let db = db(){
                var query: OpaquePointer? = nil
                if sqlite3_prepare_v2(db, sql, -1, &query, nil) == SQLITE_OK{
                    if sqlite3_step(query) == SQLITE_ROW{
                        atl = sqlite3_column_double(query, 0)
                        ctl = sqlite3_column_double(query, 1)
                        rpeATL = sqlite3_column_double(query, 2)
                        rpeCTL = sqlite3_column_double(query, 3)
                    }
                }
                sqlite3_finalize(query)
            }
        }
        return (atl, ctl, rpeATL, rpeCTL)
    }
    
    private func insertRow(inTable table: String, forType type: WorkoutType, andDay day: Day){
        var values: [String] = []
        
        for col in WarehouseColumn.dayColumns(){
            values.append(col.value(forDay: day, workoutType: type))
        }
        
        let sql = """
            INSERT INTO \(table)
            (\(tableColumns))
            VALUES
        (\(values.joined(separator: ",")))
        """
        let _: Bool = execute(sql: sql)
    }

    private func tables() -> [(tableName: String, firstDate: String)]{
        var result: [(tableName: String, firstDate: String)] = []

        if let db = db(){
            var query: OpaquePointer? = nil
            if sqlite3_prepare_v2(db, "SELECT table_name, first_date FROM Tables", -1, &query, nil) == SQLITE_OK{
                while sqlite3_step(query) == SQLITE_ROW{
                    let name: String = String(cString: sqlite3_column_text(query, 0))
                    let firstDate: String = String(cString: sqlite3_column_text(query, 1))
                    result.append((name, firstDate))
                }
            }
            sqlite3_finalize(query)
        }
        
        return result
    }
    
    private func firstDate(forTable t: String) -> String?{
        var result: String? = nil
        if let db = db(){
            var q: OpaquePointer? = nil
            if sqlite3_prepare_v2(db, "SELECT first_date FROM Tables WHERE table_name='\(t)'", -1, &q, nil) == SQLITE_OK{
                if sqlite3_step(q) == SQLITE_ROW{
                    result = String(cString: sqlite3_column_text(q, 0))
                }
            }
            sqlite3_finalize(q)
        }
        
        return result
    }
    
    private func tsb(fromTable table: String, fromDate date: String?=nil) -> [String: (ctl: Double, atl: Double)]{
        guard let db = db() else{
            return [:]
        }
        var sql: String = "SELECT date, ctl, atl FROM \(table)"
        if let d = date{
            sql = sql + " WHERE date>='\(d)'"
        }
        var query: OpaquePointer? = nil
        var result: [String: (ctl: Double, atl: Double)] = [:]
        if sqlite3_prepare_v2(db, sql, -1, &query, nil) == SQLITE_OK{
            while sqlite3_step(query) == SQLITE_ROW{
                let date: String = String(cString: sqlite3_column_text(query, 0))
                let ctl: Double = sqlite3_column_double(query, 1)
                let atl: Double = sqlite3_column_double(query, 2)
                result[date] = (ctl: ctl, atl: atl)
            }
        }
        sqlite3_finalize(query)
        return result
    }
    
    private func tablesDictionary() -> [String: WorkoutType]{
        guard let db = db() else{
            return [:]
        }
        let sql: String = "SELECT table_name, activity, activity_type, equipment FROM Tables"
        var query: OpaquePointer? = nil
        var result: [String: WorkoutType] = [:]
        if sqlite3_prepare_v2(db, sql, -1, &query, nil) == SQLITE_OK{
            while sqlite3_step(query) == SQLITE_ROW{
                let table_name: String = String(cString: sqlite3_column_text(query, 0))
                let activity: String = String(cString: sqlite3_column_text(query, 1))
                let activityType: String = String(cString: sqlite3_column_text(query, 2))
                let equipment: String = String(cString: sqlite3_column_text(query, 3))
                result[table_name] = WorkoutType(activity: activity, activityType: activityType, equipment: equipment)
            }
        }
        return result
    }
    
    private func createTable(tableName name: String, forWorkoutType type: WorkoutType, firstDate dString: String){
        
        let columnDefinitions: [String] = WarehouseColumn.dayColumns().map({$0.sqlString()})
        
        let createDayTableSQL: String = """
        CREATE TABLE \(name)(\(columnDefinitions.joined(separator: ",")));
        """
        if let db = db(){
            var query: OpaquePointer? = nil
            if sqlite3_prepare_v2(db, createDayTableSQL, -1, &query, nil) == SQLITE_OK{
                if sqlite3_step(query) == SQLITE_DONE{
                    //table created add to Tables table
                    sqlite3_finalize(query)
                    
                    let equipmentString: String = (type.equipment ?? "All").replacingOccurrences(of: " ", with: "")
                    
                    let sql: String = """
                        INSERT INTO Tables
                        (period, activity, activity_type, equipment, table_name, first_date)
                        VALUES
                        ("day", "\(type.activity ?? "All")", "\(type.activityType ?? "All")", "\(equipmentString)", "\(name)", "\(dString)")
                    """
                    var q: OpaquePointer? = nil
                    if sqlite3_prepare(db, sql, -1, &q, nil) == SQLITE_OK{
                        if sqlite3_step(q) != SQLITE_DONE{
                            print("could not execute \(sql)")
                            let errorMsg = String.init(cString: sqlite3_errmsg(db))
                            print(errorMsg)
                        }
                    }
                    sqlite3_finalize(q)
                }else{
                    print("could not execute \(createDayTableSQL)")
                    let errorMsg = String.init(cString: sqlite3_errmsg(db))
                    print(errorMsg)
                }
            }
        }
        
    }
    
    private func createTablesTable(){
        let sql: String = """
            CREATE TABLE Tables(
            period varchar(16) NOT NULL,
            activity varchar(16) NOT NULL,
            activity_type varchar(16) NOT NULL,
            equipment varchar (16) NOT NULL,
            table_name varchar(64) NOT NULL,
            first_date DATE NOT NULL,
            PRIMARY KEY (table_name)
            );
        """
        let _: Bool = execute(sql: sql)
    }
    
    private func execute(sql: String) -> Bool{

        guard let db = db() else {
            print("no db connect")
            return false
        }
        
        var query: OpaquePointer? = nil

        guard sqlite3_prepare_v2(db, sql, -1, &query, nil) == SQLITE_OK else {
            print("unable to prepare sql \(sql)")
            return false
        }

        if sqlite3_step(query) != SQLITE_DONE{
            print("could not execute \(sql)")
            let errorMsg = String.init(cString: sqlite3_errmsg(db))
            print(errorMsg)
            sqlite3_finalize(query)
            return false
        }

        sqlite3_finalize(query)
        return true
    }
    
    private func db() -> OpaquePointer?{
        if database == nil{
            var dbPointer: OpaquePointer? = nil
            if sqlite3_open(dbURL.path, &dbPointer) == SQLITE_OK{
                database = dbPointer
            }else{
                print("could not create \(dbURL)")
            }
        }
        return database
    }
    
    private func progressString(percentage: Double, start: Date, info: String) -> String{
        let s: String = String(format: "%.2f%%", percentage*100)
        return "\(s) \(timeFormatter.string(from: Date().timeIntervalSince(start))!) (\(info))"
    }

}

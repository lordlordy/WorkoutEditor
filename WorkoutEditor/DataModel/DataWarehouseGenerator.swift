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
        
        var cols: [String] = []
        for col in WarehouseColumn.dayColumns(){ cols.append(col.rawValue) }
        tableColumns = cols.joined(separator: ",")

        ctlDecay = exp(-1/42)
        ctlFactor = 1 - ctlDecay
        atlDecay = exp(-1/7)
        atlFactor = 1 - atlDecay

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
        let start: Date = Date()
        var count: Double = 0.0
        var tables: [String:WorkoutType] = [:]
        let days: [Day] = trainingDiary.ascendingOrderedDays()
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
            insertTSBMonotonyAndStrain(forTable: t.key)
            if let progress = updater{
                progress(count / denominator, "Calculating: \(progressString(percentage: count / denominator, start: start, info: "TSB, Monotony & Strain: \(t.key) (\(tCount) of \(tables.count)"))")
            }
        }

        // interpolate values
        tCount = 0
        for t in tables{
            count += 1
            tCount += 1
            interpolateValuesFor(table: t.key)
            if let progress = updater{
                progress(count / denominator, "Interpolating: \(progressString(percentage: count / denominator, start: start, info: "\(t.key) (\(tCount) of \(tables.count)"))")
            }
        }
        
        if let progress = updater{
            progress(99.9, "HRV Thresholds...")
        }
        populateHRVThresholds()
        if let progress = updater{
            progress(100.0, "DONE! \(progressString(percentage: 1.0, start: start, info: ""))")
        }
        
        print("Time: \(Date().timeIntervalSince(start))")
    }
    
    
    func createDB(){
        createTablesTable()
    }
    
    private func populateHRVThresholds(){
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
        
        let thresholds: [Maths.HRVThresholds] = Maths().hrvThresholds(orderedValues: hrvData)
        
        for t in tables(){
            let hData = thresholds.filter({$0.dString >= t.firstDate})
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
    
    private func interpolateValuesFor(table t: String){
        
        print("Interpolating values for \(t)")
        
        if let db = db(){
            for column in WarehouseColumn.interpolatedColumns(){
                guard let recordedColumn = column.recordedColumnName() else{
                    print("No recorded column for \(column) so cannot interpolate")
                    continue
                }
                let valuesSQL: String = """
                SELECT date, \(column.rawValue), \(recordedColumn) FROM \(t) ORDER BY date ASC
                """
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
        
        
    }
        
    fileprivate func performTransaction(_ db: OpaquePointer, _ dateSetValuesDict: [String : String], _ table: String) {
        let begin: String = "BEGIN TRANSACTION"
        var b: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, begin, -1, &b, nil) == SQLITE_OK{
            if sqlite3_step(b) != SQLITE_DONE{
                print("Unable to perform begin")
                let errorMsg = String.init(cString: sqlite3_errmsg(db))
                print(errorMsg)
            }
        }
        sqlite3_finalize(b)
        
        for (key, value) in dateSetValuesDict{
            let sql: String = """
            UPDATE \(table)
            SET \(value)
            WHERE date='\(key)'
            """
            var tsbPointer: OpaquePointer? = nil
            if sqlite3_prepare_v2(db, sql, -1, &tsbPointer, nil) == SQLITE_OK{
                if sqlite3_step(tsbPointer) != SQLITE_DONE{
                    print("Unable to save TSB / Strain data for \(key)")
                    let errorMsg = String.init(cString: sqlite3_errmsg(db))
                    print(errorMsg)
                }
            }
            sqlite3_finalize(tsbPointer)
        }
        
        let sqlCommit: String = "COMMIT"
        var commit: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, sqlCommit, -1, &commit, nil) == SQLITE_OK{
            if sqlite3_step(commit) != SQLITE_DONE{
                print("Unable to commit")
                let errorMsg = String.init(cString: sqlite3_errmsg(db))
                print(errorMsg)
            }
        }
        sqlite3_finalize(commit)
    }
    
    private func insertTSBMonotonyAndStrain(forTable table: String){
        let sql: String = """
            SELECT date, tss, rpe_tss FROM \(table)
            order by date ASC
        """
        print("TSB, Monotony & Strain for \(table)")
    
        var tssData: [(dString: String, tss: Double, rpe_tss: Double)] = []
        if let db = db(){
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
        
            var ctl: Double = 0.0
            var atl: Double = 0.0
            var rpe_ctl: Double = 0.0
            var rpe_atl: Double = 0.0
            var setStrings: [String:String] = [:]
            let q: RollingSumQueue = RollingSumQueue(size: monotonyDays)
            let rpeQ: RollingSumQueue = RollingSumQueue(size: monotonyDays)
            let maths: Maths = Maths()
            
            for t in tssData{
                setStrings[t.dString] = ""
            }
            
            for d in tssData{
                ctl = d.tss * ctlFactor + ctl * ctlDecay
                atl = d.tss * atlFactor + ctl * atlDecay
                rpe_ctl = d.rpe_tss * ctlFactor + rpe_ctl * ctlDecay
                rpe_atl = d.rpe_tss * atlFactor + rpe_ctl * atlDecay
                
                _ = q.addAndReturnSum(value: d.tss)
                _ = rpeQ.addAndReturnSum(value: d.rpe_tss)
                let mon = maths.monotonyAndStrain(q.array())
                let rpe_mon = maths.monotonyAndStrain(rpeQ.array())

                
                setStrings[d.dString] = """
                ctl=\(ctl), atl=\(atl), tsb=\(ctl-atl), rpe_ctl=\(rpe_ctl), rpe_atl=\(rpe_atl), rpe_tsb=\(rpe_ctl-rpe_atl),
                monotony=\(mon.monotony), strain=\(mon.strain), rpe_monotony=\(rpe_mon.monotony), rpe_strain=\(rpe_mon.strain)
                """
            }
            performTransaction(db, setStrings, table)
            
        }
        
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
        if let db = db(){
            var query: OpaquePointer? = nil
            if sqlite3_prepare_v2(db, sql, -1, &query, nil) == SQLITE_OK{
                if sqlite3_step(query) != SQLITE_DONE{
                    print("could not execute \(sql)")
                    let errorMsg = String.init(cString: sqlite3_errmsg(db))
                    print(errorMsg)
                }
            }
            sqlite3_finalize(query)
        }
        
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

                    let sql: String = """
                        INSERT INTO Tables
                        (period, activity, activity_type, equipment, table_name, first_date)
                        VALUES
                        ("day", "\(type.activity ?? "All")", "\(type.activityType ?? "All")", "\(type.equipment ?? "All")", "\(name)", "\(dString)")
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
        
        if let db = db(){
            var query: OpaquePointer? = nil
            if sqlite3_prepare_v2(db, sql, -1, &query, nil) == SQLITE_OK{
                if sqlite3_step(query) != SQLITE_DONE{
                    print("could not execute \(sql)")
                    let errorMsg = String.init(cString: sqlite3_errmsg(db))
                    print(errorMsg)
                }
            }
            sqlite3_finalize(query)
        }
        
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

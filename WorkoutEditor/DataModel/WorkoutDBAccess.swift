//
//  WorkoutDBAccess.swift
//  WorkoutEditor
//
//  Created by Steven Lord on 30/08/2019.
//  Copyright © 2019 Steven Lord. All rights reserved.
//

import SQLite3
import Foundation

enum TableName: String{
    case Day = "Day"
    case Reading = "Reading"
    case Workout = "Workout"
}

class WorkoutDBAccess{
    
    private let createDayTableSQL: String = """
        CREATE TABLE Day(
          date Date NOT NULL UNIQUE,
          type varchar (16) NOT NULL,
          comments TEXT NOT NULL,
          PRIMARY KEY (date)
        );
    """
    
    private let createReadingTableSQL: String = """
            CREATE TABLE Reading(
                primary_key varchar(32) NOT NULL,
                date Date NOT NULL,
                type varchar(16) NOT NULL,
                value REAL NOT NULL,
                PRIMARY KEY (primary_key),
            FOREIGN KEY (date) REFERENCES Day(date)
            );
    """
    
    private let createWorkoutTableSQL: String = """
            CREATE TABLE \(TableName.Workout.rawValue)(
                primary_key varchar(32) NOT NULL,
                date Date NOT NULL,
                workout_number INTEGER NOT NULL,
                activity varchar(16) NOT NULL,
                activity_type varchar(16) NOT NULL,
                equipment varchar(32) NOT NULL,
                seconds INTEGER NOT NULL,
                rpe REAL NOT NULL,
                tss INTEGER NOT NULL,
                tss_method varchar(16) NOT NULL,
                km REAL NOT NULL,
                kj INTEGER NOT NULL,
                ascent_metres INTEGER NOT NULL,
                reps INTEGER NOT NULL,
                is_race BOOLEAN NOT NULL,
                cadence INTEGER,
                watts INTEGER NOT NULL,
                watts_estimated BOOLEAN NOT NULL,
                heart_rate INTEGER NOT NULL,
                is_brick BOOLEAN NOT NULL,
                keywords TEXT NOT NULL,
                comments TEXT NOT NULL,
                last_save Date,
                PRIMARY KEY (primary_key)
            );
    """
    
    private let createRaceResultTableSQL: String = """
        CREATE TABLE RaceResult(
            primary_key varchar(32) NOT NULL,
            date Date NOT NULL,
            race_number INTEGER NOT NULL,
            type varchar(16) NOT NULL,
            brand varchar(16) NOT NULL,
            distance varchar(16) NOT NULL,
            name varchar(64) NOT NULL,
            category varchar(16) NOT NULL,
            overall_position INTEGER NOT NULL,
            category_position INTEGER NOT NULL,
            swim_seconds INTEGER NOT NULL,
            t1_seconds INTEGER NOT NULL,
            bike_seconds INTEGER NOT NULL,
            t2_seconds INTEGER NOT NULL,
            run_seconds INTEGER NOT NULL,
            swim_km REAL NOT NULL,
            bike_km REAL NOT NULL,
            run_km REAL NOT NULL,
            comments TEXT NOT NULL,
            race_report TEXT NOT NULL,
            last_save Date,
            PRIMARY KEY (primary_key)
        );
    """
    
    public static var shared: WorkoutDBAccess = WorkoutDBAccess()
    
    // default Database
    private var dbURL: URL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "stevenlord.me.uk.SharedTrainingDiary")!.appendingPathComponent("Workout.sqlite3")

    private var df: DateFormatter = DateFormatter()
    private var database: OpaquePointer?
    var dbName: String{
        return dbURL.lastPathComponent
    }
    
    func createDatabase(atURL url: URL){
        let _ = createDB(atURL: url)
    }
    
    public func setDBURL(toURL url: URL){
        dbURL = url
        database = nil
    }
    public func getDBURL() -> URL{
        return dbURL
    }
    
    func dayTypes() -> [String]{
        var types: [String] = []
        if let db = db(){
            var query: OpaquePointer? = nil
            if sqlite3_prepare_v2(db, "SELECT DISTINCT(type) FROM Day", -1, &query, nil) != SQLITE_OK{
                print("unable to prepare query")
                print("error: \(String(cString: sqlite3_errmsg(db)))")
            }
            //have a query
            while(sqlite3_step(query)) == SQLITE_ROW{
                types.append(String(cString: sqlite3_column_text(query, 0)))
            }
        }
        return types
    }
    
    func activities() -> [String]{ return types(forTable: "\(TableName.Workout.rawValue)", andColumn: "activity") }
    func activityTypes() -> [String]{ return types(forTable: "\(TableName.Workout.rawValue)", andColumn: "activity_type") }
    func equipmentTypes() -> [String]{ return types(forTable: "\(TableName.Workout.rawValue)", andColumn: "equipment") }
    func tssMethods() -> [String]{ return types(forTable: "\(TableName.Workout.rawValue)", andColumn: "tss_method") }
    func raceTypes() -> [String]{ return types(forTable: "RaceResult", andColumn: "type") }
    func raceBrands() -> [String]{ return types(forTable: "RaceResult", andColumn: "brand") }
    func raceDistances() -> [String]{ return types(forTable: "RaceResult", andColumn: "distance") }
    func ageCategories() -> [String]{ return types(forTable: "RaceResult", andColumn: "category") }

    private func types(forTable table: String, andColumn col: String) -> [String]{
        var types: [String] = []
        if let db = db(){
            var query: OpaquePointer? = nil
            if sqlite3_prepare_v2(db, "SELECT DISTINCT(\(col)) FROM \(table)", -1, &query, nil) != SQLITE_OK{
                print("unable to prepare query")
                print("error: \(String(cString: sqlite3_errmsg(db)))")
            }
            //have a query
            while(sqlite3_step(query)) == SQLITE_ROW{
                let str: String = String(cString: sqlite3_column_text(query, 0))
                if str != ""{
                    types.append(str)
                }
            }
        }

        return types
    }
    
    func readingTypes() -> Set<String>{
        var types:  Set<String> = Set<String>()
        if let db = db(){
            var query: OpaquePointer? = nil
            if sqlite3_prepare_v2(db, "SELECT DISTINCT(type) FROM Reading", -1, &query, nil) != SQLITE_OK{
                print("unable to prepare query")
                print("error: \(String(cString: sqlite3_errmsg(db)))")
            }
            //have a query
            while(sqlite3_step(query)) == SQLITE_ROW{
                types.insert(String(cString: sqlite3_column_text(query, 0)))
            }
        }
        return types
    }
    
    
    func save(day d: Day){
        var sqlString: String = ""
        if exists(day: d){
            sqlString = """
                    UPDATE Day
                    SET type='\(d.type)', comments="\(d.comments)"
                    WHERE date='\(df.string(from: d.date))'
                """
            print(sqlString)
        }else{
            sqlString = """
                    INSERT INTO Day (date, type, comments)
                    VALUES ('\(df.string(from: d.date))', '\(d.type)', "\(d.comments)")
            """
        }
        let _ = execute(sql: sqlString)
        
        for r in d.readings{
            save(reading: r)
        }
        
        for w in d.workouts{
            save(workout: w)
        }
        

    }
    
    func save(reading r: Reading){
        var sqlString: String = ""
        if exists(reading: r){
            sqlString = """
            UPDATE Reading
            SET value=\(r.value)
            WHERE date='\(df.string(from: r.date))' and type='\(r.type)'
            """
        }else{
            sqlString = """
            INSERT INTO Reading (primary_key, date, type, value)
            VALUES ('\(r.primaryKey)','\(df.string(from: r.date))', '\(r.type)', \(r.value))
            """
        }
        let _ = execute(sql: sqlString)

    }
    
    func delete(workout w: Workout){
        guard let lastSave = w.lastSave else{
            // can't remove if it's never been saved.
            return
        }
        
        let deleteSQL: String = """
            DELETE FROM \(TableName.Workout.rawValue)
            WHERE date="\(w.day.iso8601DateString)" AND workout_number=\(w.workoutNumber) AND last_save="\(ISO8601DateFormatter().string(from: lastSave))"
        """
        if execute(sql: deleteSQL){
            print("DELETED \(w.description)")
        }else{
            print("Unable to delete \(w.description)")
        }
    }
    
    func save(workout w: Workout){
        var sqlString: String = ""
        if exists(workout: w){
            sqlString = """
            UPDATE \(TableName.Workout.rawValue)
            SET
            activity='\(w.activity)',
            activity_type='\(w.activityType)',
            equipment='\(w.equipment)',
            seconds=\(w.seconds),
            rpe=\(w.rpe),
            tss=\(w.tss),
            tss_method='\(w.tssMethod)',
            km=\(w.km),
            kj=\(w.kj),
            ascent_metres=\(w.ascentMetres),
            reps=\(w.reps),
            is_race=\(w.isRace),
            cadence=\(w.cadence),
            watts=\(w.watts),
            watts_estimated=\(w.wattsEstimated),
            heart_rate=\(w.heartRate),
            is_brick=\(w.isBrick),
            keywords="\(w.keywords)",
            comments="\(w.comments)"
            last_save="\(ISO8601DateFormatter().string(from: Date()))"
            WHERE date='\(df.string(from: w.date))' and workout_number=\(w.workoutNumber)
            """
        }else{
            sqlString = """
            INSERT INTO \(TableName.Workout.rawValue)
            (primary_key, date, workout_number, activity, activity_type, equipment, seconds, rpe, tss, tss_method, km, kj, ascent_metres, reps, is_race, cadence, watts, watts_estimated, heart_rate, is_brick, keywords, comments, last_save)
            VALUES
            ('\(w.primaryKey)', '\(df.string(from: w.date))', \(w.workoutNumber), '\(w.activity)', '\(w.activityType)', '\(w.equipment)', \(w.seconds), \(w.rpe), \(w.tss), '\(w.tssMethod)', \(w.km), \(w.kj), \(w.ascentMetres), \(w.reps), \(w.isRace), \(w.cadence), \(w.watts), \(w.wattsEstimated), \(w.heartRate), \(w.isBrick), "\(w.keywords)", "\(w.comments)", "\(ISO8601DateFormatter().string(from: Date()))")
            """
        }
        let _ = execute(sql: sqlString)

    }
    
    func delete(raceResult rr: RaceResult){
        guard let lastSave = rr.lastSave else{
            // can't remove if it's never been saved.
            return
        }
        
        let deleteSQL: String = """
        DELETE FROM RaceResult
        WHERE date="\(rr.iso8601DateString)" AND race_number=\(rr.raceNumber) AND last_save="\(ISO8601DateFormatter().string(from: lastSave))"
        """
        if execute(sql: deleteSQL){
            print("DELETED \(rr.description)")
        }else{
            print("Unable to delete \(rr.description)")
        }
    }
    
    func save(raceResult r: RaceResult){
        var sqlString: String = ""
        if exists(raceResult: r){
            sqlString = """
            UPDATE RaceResult
            SET
            type="\(r.type)",
            brand="\(r.brand)",
            distance="\(r.distance)",
            name="\(r.name)",
            category="\(r.category)",
            overall_position=\(r.overallPosition),
            category_position=\(r.categoryPosition),
            swim_seconds=\(r.swimSeconds),
            t1_seconds=\(r.t1Seconds),
            bike_seconds=\(r.bikeSeconds),
            t2_seconds=\(r.t2Seconds),
            run_seconds=\(r.runSeconds),
            swim_km=\(r.swimKM),
            bike_km=\(r.bikeKM),
            run_km=\(r.runKM),
            comments="\(r.comments)",
            race_report="\(r.raceReport)"
            last_save="\(ISO8601DateFormatter().string(from: Date()))"
            WHERE date='\(df.string(from: r.date))' and race_number=\(r.raceNumber)
            """
        }else{
            sqlString = """
            INSERT INTO RaceResult
            (primary_key, date, race_number, type, brand, distance, name, category, overall_position, category_position, swim_seconds, t1_seconds, bike_seconds, t2_seconds, run_seconds, swim_km, bike_km, run_km, comments, race_report, last_save)
            VALUES
            ('\(r.primaryKey)', "\(r.iso8601DateString)", \(r.raceNumber), "\(r.type)", "\(r.brand)", "\(r.distance)", "\(r.name)", "\(r.category)", \(r.overallPosition), \(r.categoryPosition), \(r.swimSeconds), \(r.t1Seconds), \(r.bikeSeconds), \(r.t2Seconds), \(r.runSeconds), \(r.swimKM), \(r.bikeKM), \(r.runKM), "\(r.comments)", "\(r.raceReport)", "\(ISO8601DateFormatter().string(from: Date()))")
            """
        }
        let _ = execute(sql: sqlString)
        
    }
    
    func createTrainingDiary() -> TrainingDiary{
        let td: TrainingDiary = TrainingDiary()
        let start = Date()
        if let db = db(){
            var query: OpaquePointer? = nil
            if sqlite3_prepare_v2(db, "SELECT date, type, comments FROM Day", -1, &query, nil) != SQLITE_OK{
                print("unable to prepare query")
                print("error: \(String(cString: sqlite3_errmsg(db)))")
            }
            //have a query
            while(sqlite3_step(query)) == SQLITE_ROW{
                let dString: String  = String(cString: sqlite3_column_text(query, 0))
                let date: Date = df.date(from: dString)!
                let type: String  = String(cString: sqlite3_column_text(query, 1))
                let comments: String  = String(cString: sqlite3_column_text(query, 2))

                let dc: DateComponents = Calendar.current.dateComponents([.year, .month, .day], from: date)
                
                let d: Day = Day(date: Calendar.current.date(from: DateComponents(year: dc.year!, month: dc.month!, day: dc.day!, hour: 12, minute: 00, second: 00))!, type: type, comments: comments, trainingDiary: td)
                if !td.add(day: d){
                    print("Unable to add \(d) as day on that date already exists")
                }
            }
            sqlite3_finalize(query)
            query = nil

            if sqlite3_prepare_v2(db, "SELECT date, type, value FROM Reading", -1, &query, nil) != SQLITE_OK{
                print("unable to prepare query")
                print("error: \(String(cString: sqlite3_errmsg(db)))")
            }
            while(sqlite3_step(query)) == SQLITE_ROW{
                let dString: String  = String(cString: sqlite3_column_text(query, 0))
                let date: Date = df.date(from: dString)!
                let type: String  = String(cString: sqlite3_column_text(query, 1))
                let value: Double  = sqlite3_column_double(query, 2)

                if let d = td.day(forDate: date){
                    d.add(readings: [Reading(type: type, value: value, parent: d)])
                }
            }
            sqlite3_finalize(query)
            query = nil

            let wQuery: String = """
                SELECT date, workout_number, activity, activity_type, equipment, seconds, rpe, tss, tss_method, km, kj, ascent_metres, reps, is_race, cadence, watts, watts_estimated, heart_rate, is_brick, keywords, comments, last_save
                FROM \(TableName.Workout.rawValue)
            """
            if sqlite3_prepare_v2(db, wQuery, -1, &query, nil) != SQLITE_OK{
                print("unable to prepare query")
                print("error: \(String(cString: sqlite3_errmsg(db)))")
            }
            while(sqlite3_step(query)) == SQLITE_ROW{
                let dString: String  = String(cString: sqlite3_column_text(query, 0))
                let date: Date = df.date(from: dString)!
                let workout_number: Int = Int(sqlite3_column_int(query, 1))
                let activity: String = String(cString: sqlite3_column_text(query, 2))
                let activity_type: String = String(cString: sqlite3_column_text(query, 3))
                let equipment: String = String(cString: sqlite3_column_text(query, 4))
                let seconds: Int = Int(sqlite3_column_int(query, 5))
                let rpe: Double = sqlite3_column_double(query, 6)
                let tss: Int = Int(sqlite3_column_int(query, 7))
                let tss_method: String = String(cString: sqlite3_column_text(query, 8))
                let km: Double = sqlite3_column_double(query, 9)
                let kj: Int = Int(sqlite3_column_int(query, 10))
                let ascent_metres: Int = Int(sqlite3_column_int(query, 11))
                let reps: Int = Int(sqlite3_column_int(query, 12))
                let is_race: Bool = Int(sqlite3_column_int(query, 13)) > 0
                let cadence: Int = Int(sqlite3_column_int(query, 14))
                let watts: Int = Int(sqlite3_column_int(query, 15))
                let watts_estimated: Bool = Int(sqlite3_column_int(query, 16)) > 0
                let heart_rate: Int = Int(sqlite3_column_int(query, 17))
                let is_brick: Bool = Int(sqlite3_column_int(query, 18)) > 0
                let keywords: String = String(cString: sqlite3_column_text(query, 19))
                let comments: String = String(cString: sqlite3_column_text(query, 20))
                let lastSaveString: String = String(cString: sqlite3_column_text(query, 21))
                let lastSave: Date = ISO8601DateFormatter().date(from: lastSaveString)!

                
                if let d = td.day(forDate: date){
                    let w: Workout = Workout(day: d, workout_number: workout_number, activity: activity, activity_type: activity_type, equipment: equipment, seconds: seconds, rpe: rpe, tss: tss, tss_method: tss_method, km: km, kj: kj, ascent_metres: ascent_metres, reps: reps, is_race: is_race, cadence: cadence, watts: watts, watts_estimated: watts_estimated, heart_rate: heart_rate, is_brick: is_brick, keywords: keywords, comments: comments)
                    w.lastSave = lastSave
                    d.add(workout: w)
                }
            }
            sqlite3_finalize(query)
            query = nil
            
            var raceResults: [RaceResult] = []
            // get race results
            let raceResultsSQL: String = """
                SELECT
                date, race_number, type, brand, distance, name, category, overall_position, category_position, swim_seconds, t1_seconds, bike_seconds, t2_seconds, run_seconds, swim_km, bike_km, run_km, comments, race_report, last_save
                FROM RaceResult
            """
            if sqlite3_prepare_v2(db, raceResultsSQL, -1, &query, nil) != SQLITE_OK{
                print("unable to prepare query")
                print("error: \(String(cString: sqlite3_errmsg(db)))")
            }
            while(sqlite3_step(query)) == SQLITE_ROW{
                let dString: String  = String(cString: sqlite3_column_text(query, 0))
                let date: Date = df.date(from: dString)!
                let race_number: Int = Int(sqlite3_column_int(query, 1))
                let type: String = String(cString: sqlite3_column_text(query, 2))
                let brand: String = String(cString: sqlite3_column_text(query, 3))
                let distance: String = String(cString: sqlite3_column_text(query, 4))
                let name: String = String(cString: sqlite3_column_text(query, 5))
                let category: String = String(cString: sqlite3_column_text(query, 6))
                let overall_position: Int = Int(sqlite3_column_int(query, 7))
                let category_position: Int = Int(sqlite3_column_int(query, 8))
                let swim_seconds: Int = Int(sqlite3_column_int(query, 9))
                let t1_seconds: Int = Int(sqlite3_column_int(query, 10))
                let bike_seconds: Int = Int(sqlite3_column_int(query, 11))
                let t2_seconds: Int = Int(sqlite3_column_int(query, 12))
                let run_seconds: Int = Int(sqlite3_column_int(query, 13))
                let swim_km: Double = sqlite3_column_double(query, 14)
                let bike_km: Double = sqlite3_column_double(query, 15)
                let run_km: Double = sqlite3_column_double(query, 16)
                let comments: String = String(cString: sqlite3_column_text(query, 17))
                let race_report: String = String(cString: sqlite3_column_text(query, 18))
                let lastSaveString: String  = String(cString: sqlite3_column_text(query, 19))
                let lastSave: Date = ISO8601DateFormatter().date(from: lastSaveString)!

                let rr: RaceResult = RaceResult(date: date, raceNumber: race_number, type: type, brand: brand, distance: distance, name: name, category: category, overallPosition: overall_position, categoryPosition: category_position, swimSeconds: swim_seconds, t1Seconds: t1_seconds, bikeSeconds: bike_seconds, t2Seconds: t2_seconds, runSeconds: run_seconds, swimKM: swim_km, bikeKM: bike_km, runKM: run_km, comments: comments, raceReport: race_report)
                rr.lastSave = lastSave
                raceResults.append(rr)
            }
            sqlite3_finalize(query)
            
            td.raceResults = raceResults
            
        }else{
            print("no valid DB connected to")
        }

        print("Cache built in \(Date().timeIntervalSince(start))s")
        return td
    }
    
    
    private init(){
        df.dateFormat = "yyyy-MM-dd"
        df.timeZone = Calendar.current.timeZone
    }
    
    
    private func execute(sql: String) -> Bool{
        if let db = db(){
            var query: OpaquePointer? = nil
            if sqlite3_prepare_v2(db, sql, -1, &query, nil) == SQLITE_OK{
                if sqlite3_step(query) == SQLITE_DONE{
                    sqlite3_finalize(query)
                    return true
                }else{
                    print("could not execute \(sql)")
                    let errorMsg = String.init(cString: sqlite3_errmsg(db))
                    print(errorMsg)
                }
            }
            sqlite3_finalize(query)
        }
        return false
    }
    
    private func exists(day d: Day) -> Bool{
        if let db = db(){
            let qString: String = "SELECT date FROM Day WHERE date='\(df.string(from: d.date))'"
            var query: OpaquePointer? = nil
            if sqlite3_prepare_v2(db, qString, -1, &query, nil) == SQLITE_OK{
                let success = sqlite3_step(query) == SQLITE_ROW
                sqlite3_finalize(query)
                return success
            }
            sqlite3_finalize(query)
        }
        return false
    }
    
    private func exists(reading r: Reading) -> Bool{
        if let db = db(){
            let qString: String = "SELECT date, type FROM Reading WHERE date='\(df.string(from: r.date))' and type='\(r.type)'"
            var query: OpaquePointer? = nil
            if sqlite3_prepare_v2(db, qString, -1, &query, nil) == SQLITE_OK{
                let success = sqlite3_step(query) == SQLITE_ROW
                sqlite3_finalize(query)
                return success
            }else{
                let errorMsg = String.init(cString: sqlite3_errmsg(db))
                print(errorMsg)
            }
            sqlite3_finalize(query)
        }
        return false
    }
    
    private func exists(workout w: Workout) -> Bool{
        if let db = db(){
            let qString: String = "SELECT date, workout_number FROM \(TableName.Workout.rawValue) WHERE date='\(df.string(from: w.date))' and workout_number=\(w.workoutNumber)"
            var query: OpaquePointer? = nil
            if sqlite3_prepare_v2(db, qString, -1, &query, nil) == SQLITE_OK{
                let success = sqlite3_step(query) == SQLITE_ROW
                sqlite3_finalize(query)
                return success
            }
            sqlite3_finalize(query)
        }
        return false
    }
    
    private func exists(raceResult r: RaceResult) -> Bool{
        if let db = db(){
            let qString: String = "SELECT date, race_number FROM RaceResult WHERE date='\(df.string(from: r.date))' and race_number=\(r.raceNumber)"
            var query: OpaquePointer? = nil
            if sqlite3_prepare_v2(db, qString, -1, &query, nil) == SQLITE_OK{
                let success = sqlite3_step(query) == SQLITE_ROW
                sqlite3_finalize(query)
                return success
            }
            sqlite3_finalize(query)
        }
        return false
    }
    
    private func db() -> OpaquePointer?{
        if database == nil{
            var dbPointer: OpaquePointer? = nil
            if sqlite3_open(dbURL.path, &dbPointer) == SQLITE_OK{
                database = dbPointer
            }else{
                print("Failed to connect to DB \(dbURL). Trying to create...")
                database = createDB(atURL: dbURL)
            }
        }
        return database
    }
    
    private func createDB(atURL url: URL) -> OpaquePointer?{
        var db: OpaquePointer? = nil
        
        if sqlite3_open(url.path, &db) == SQLITE_OK{
            var query: OpaquePointer? = nil
            if sqlite3_prepare_v2(db, createDayTableSQL, -1, &query, nil) != SQLITE_OK{
                print("unable to prepare query")
                print("error: \(String(cString: sqlite3_errmsg(db)))")
            }else{
                if(sqlite3_step(query)) == SQLITE_DONE{
                    print("Created Day Table")
                }else{
                    print("Unable to create Day table")
                }
                sqlite3_finalize(query)
                query = nil
            }
            
            if sqlite3_prepare_v2(db, createReadingTableSQL, -1, &query, nil) != SQLITE_OK{
                print("unable to prepare query")
                print("error: \(String(cString: sqlite3_errmsg(db)))")
            }else{
                if(sqlite3_step(query)) == SQLITE_DONE{
                    print("Created Reading Table")
                }else{
                    print("Unable to create Reading table")
                }
                sqlite3_finalize(query)
                query = nil
            }

            if sqlite3_prepare_v2(db, createWorkoutTableSQL, -1, &query, nil) != SQLITE_OK{
                print("unable to prepare query")
                print("error: \(String(cString: sqlite3_errmsg(db)))")
            }else{
                if(sqlite3_step(query)) == SQLITE_DONE{
                    print("Created Workout Table")
                }else{
                    print("Unable to create Workout table")
                }
                sqlite3_finalize(query)
            }

            if sqlite3_prepare_v2(db, createRaceResultTableSQL, -1, &query, nil) != SQLITE_OK{
                print("unable to prepare query")
                print("error: \(String(cString: sqlite3_errmsg(db)))")
            }else{
                if(sqlite3_step(query)) == SQLITE_DONE{
                    print("Created Race Result Table")
                }else{
                    print("Unable to create Race Result table")
                }
                sqlite3_finalize(query)
            }

            return db
        }else{
            print("Failed to connect to DB \(url)")
            return nil
        }
        
    }
    
}

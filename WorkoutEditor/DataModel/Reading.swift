//
//  DayReading.swift
//  WorkoutEditor
//
//  Created by Steven Lord on 30/08/2019.
//  Copyright © 2019 Steven Lord. All rights reserved.
//

import Foundation
import CloudKit

class Reading: NSObject{
    
    @objc var primaryKey: String { return "\(day.iso8601DateString)-\(type)" }
    @objc var primary_key: String { return self.primaryKey }
    @objc var date: Date{ return day.date }
    @objc var type: String
    @objc var value: Double
    @objc var day: Day
    override var description: String{ return "\(type):\(value)"}
    
    
    init(type: String, value: Double, parent: Day){
        self.type = type
        self.value = value
        self.day = parent
    }
    
}

extension Reading{
    override func setValue(_ value: Any?, forKey key: String) {
        super.setValue(value, forKey: key)
        day.unsavedChanges = true
    }
}

extension Reading: AsCloudKitProtocol{
    func asCKRecord() -> CKRecord {

        let record: CKRecord = CKRecord(recordType: TableName.Reading.rawValue, recordID: ckRecordID())
        
        for c in ReadingColumn.allCases{
            record.setValue(self.value(forKey: c.rawValue), forKey: c.rawValue)
        }
        
        record["day"] = CKRecord.Reference(recordID: self.day.ckRecordID(), action: .deleteSelf)
        
        return record
    }
    
    func ckRecordID() -> CKRecord.ID {
        return CKRecord.ID(recordName: self.primaryKey, zoneID: CKRecordZone.default().zoneID)
    }
    
    
    
}

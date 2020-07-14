//
//  File.swift
//  WorkoutEditor
//
//  Created by Steven Lord on 01/07/2020.
//  Copyright © 2020 Steven Lord. All rights reserved.
//

import Foundation
import CloudKit

protocol AsCloudKitProtocol {
    func asCKRecord() -> CKRecord
    func ckRecordID() -> CKRecord.ID
}

//
//  NumberToTimeFormatter.swift
//  WorkoutEditor
//
//  Created by Steven Lord on 10/09/2019.
//  Copyright © 2019 Steven Lord. All rights reserved.
//

import Cocoa

class NumberToTimeFormatter: ValueTransformer {
    
    private var formatter: DateComponentsFormatter
    
    override init() {
        formatter = DateComponentsFormatter()
        formatter.allowedUnits = [ .hour, .minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        super.init()
    }
    
    //What do I transform
    override class func transformedValueClass() -> AnyClass {return NSNumber.self}
    
    override class func allowsReverseTransformation() -> Bool {return true}
    
    override func transformedValue(_ value: Any?) -> Any? {
        if let s = value as? TimeInterval{
            return formatter.string(from: s)
        }
        if let s = value as? Int{
            return formatter.string(from: TimeInterval(s))
        }
        
        return nil
        
    }
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let type = value as? NSString else { return nil }
        let myString: String = type as String
        let b = myString.split(separator: ":") as [NSString]
        if b.count > 2{
            let total = b[0].integerValue*3600 + b[1].integerValue*60 + b[2].integerValue
            return NSNumber(value: total)
        }else{
            return 0.0
        }
    }
    
}

//
//  JSONImporter.swift
//  WorkoutEditor
//
//  Created by Steven Lord on 09/09/2019.
//  Copyright © 2019 Steven Lord. All rights reserved.
//

import Foundation

class JSONImporter{
    
    public func importDiary(fromURL url: URL){
        
        do{
            let data: Data = try Data.init(contentsOf: url)
            let jsonData  = try JSONSerialization.jsonObject(with: data, options: [.allowFragments, .mutableContainers])
            let jsonDict = jsonData as? [String:Any]
            print(jsonDict!)
        }catch{
            print("error initialising Training Diary for URL: " + url.absoluteString)
        }
        
    }
    
}

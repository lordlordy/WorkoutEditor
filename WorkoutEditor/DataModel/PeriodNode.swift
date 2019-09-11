//
//  PeriodNode.swift
//  WorkoutEditor
//
//  Created by Steven Lord on 10/09/2019.
//  Copyright © 2019 Steven Lord. All rights reserved.
//

import Foundation

@objc protocol PeriodNode{
    
    @objc var name:             String      { get }
    @objc var children:         [PeriodNode]{ get }
    @objc var childCount:       Int         { get }
    @objc var totalKM:          Double      { get }
    @objc var totalSeconds:     TimeInterval{ get }
    @objc var totalTSS:         Double      { get }
    @objc var swimKM:           Double      { get }
    @objc var swimSeconds:      TimeInterval{ get }
    @objc var swimTSS:          Double      { get }
    @objc var bikeKM:           Double      { get }
    @objc var bikeSeconds:      TimeInterval{ get }
    @objc var bikeTSS:          Double      { get }
    @objc var runKM:            Double      { get }
    @objc var runSeconds:       TimeInterval{ get }
    @objc var runTSS:           Double      { get }
    @objc var fromDate:         Date        { get }
    @objc var toDate:           Date        { get }
    @objc var isLeaf:           Bool        { get }
    @objc var leafCount:        Int         { get }
    @objc var type:             String      { get }
    
    @objc var sleep:            Double      { get }
    @objc var sleepQuality:     Double      { get }
    @objc var motivation:       Double      { get }
    @objc var fatigue:          Double      { get }
    @objc var kg:               Double      { get }
    @objc var fatPercentage:    Double      { get }
    @objc var restingHR:        Double      { get }
    @objc var sdnn:             Double      { get }
    @objc var rMSSD:            Double      { get }
    
}

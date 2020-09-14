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
    @objc var totalTSS:         Int         { get }
    @objc var swimKM:           Double      { get }
    @objc var swimSeconds:      TimeInterval{ get }
    @objc var swimTSS:          Int         { get }
    @objc var bikeKM:           Double      { get }
    @objc var bikeSeconds:      TimeInterval{ get }
    @objc var bikeTSS:          Int         { get }
    @objc var runKM:            Double      { get }
    @objc var runSeconds:       TimeInterval{ get }
    @objc var runTSS:           Int         { get }
    @objc var fromDate:         Date        { get }
    @objc var toDate:           Date        { get }
    @objc var isLeaf:           Bool        { get }
    @objc var leafCount:        Int         { get }
    @objc var type:             String      { get }
    @objc var sleep:            Double      { get }
    @objc var sleepQualityScore:Double      { get }
    @objc var motivation:       Double      { get }
    @objc var fatigue:          Double      { get }
    @objc var kg:               Double      { get }
    @objc var fatPercentage:    Double      { get }
    @objc var restingHR:        Int         { get }
    @objc var sdnn:             Double      { get }
    @objc var rMSSD:            Double      { get }
    @objc var pressUps:         Int         { get }
    @objc var unsavedChanges:   Bool        { get }
    @objc var days:             Set<Day>    { get }
    
    @objc var swimWorkoutCount: Int         { get }
    @objc var bikeWorkoutCount: Int         { get }
    @objc var runWorkoutCount:  Int         { get }
    
    // Training Stress Balance values
    @objc var ctl:              Double      { get }
    @objc var atl:              Double      { get }
    @objc var tsb:              Double      { get }
    @objc var ctlSwim:          Double      { get }
    @objc var atlSwim:          Double      { get }
    @objc var tsbSwim:          Double      { get }
    @objc var ctlBike:          Double      { get }
    @objc var atlBike:          Double      { get }
    @objc var tsbBike:          Double      { get }
    @objc var ctlRun:           Double      { get }
    @objc var atlRun:           Double      { get }
    @objc var tsbRun:           Double      { get }

}

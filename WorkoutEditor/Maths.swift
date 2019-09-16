//
//  Maths.swift
//  WorkoutEditor
//
//  Created by Steven Lord on 13/09/2019.
//  Copyright © 2019 Steven Lord. All rights reserved.
//

import Foundation

class Maths{
    
    var hrvThresholdDays: Int = 91
    var hrvOffPercentile: Double = 0.05
    var hrvEasyPercentile: Double = 0.25
    var hrvHardPercentile: Double = 0.75
    
    struct HRVThresholds{
        var dString: String
        var sdnnOff: Double
        var sdnnEasy: Double
        var sdnnHard: Double
        var rmssdOff: Double
        var rmssdEasy: Double
        var rmssdHard: Double
    }
    
    func hrvThresholds(orderedValues: [(dString: String, sdnn: Double, rmssd: Double)]) -> [HRVThresholds]{
        var result: [HRVThresholds] = []
        let sQ: RollingSumQueue = RollingSumQueue(size: hrvThresholdDays)
        let rQ: RollingSumQueue = RollingSumQueue(size: hrvThresholdDays)

        let offSDs = normalCDFInverse(hrvOffPercentile)
        let easySDs = normalCDFInverse(hrvEasyPercentile)
        let hardSDs = normalCDFInverse(hrvHardPercentile)
        
        for d in orderedValues{
            
            let rMean = rQ.addAndReturnAverage(value:d.rmssd)
            let rStDev = standardDeviation(rQ.array())
            let rHard = rMean + hardSDs * rStDev
            let rEasy = rMean + easySDs * rStDev
            let rOff = rMean + offSDs * rStDev
            
            let sMean = sQ.addAndReturnAverage(value: d.sdnn)
            let sStDev = standardDeviation(sQ.array())
            let sHard = sMean + hardSDs * sStDev
            let sEasy = sMean + easySDs * sStDev
            let sOff = sMean + offSDs * sStDev
            
            result.append(HRVThresholds(dString: d.dString, sdnnOff: sOff, sdnnEasy: sEasy, sdnnHard: sHard, rmssdOff: rOff, rmssdEasy: rEasy, rmssdHard: rHard))
            
        }
        
        return result
    }
    
    
    func interpolateZeros(values: [Double]) -> [(index: Int, value: Double)]{
        // this represents the indexes either side of values that need interpolating
        var zeroBounds: [(Int,Int)] = []
        var foundFirstNonZero: Bool = false
        var lookingForZero: Bool = true
        var index: Int = 0
        var item: (Int,Int) = (0,0)
        var result: [(index: Int, value: Double)] = []
        for v in values{
            foundFirstNonZero = foundFirstNonZero || v > 0.0
            if foundFirstNonZero{
                if lookingForZero{
                    if v == 0.0{
                        item = (index-1,0)
                        lookingForZero = false
                    }
                }else{
                    if v > 0.0{
                        item = (item.0, index)
                        lookingForZero = true
                        zeroBounds.append(item)
                        item = (0,0)
                    }
                }
            }
            index += 1
        
        }
        if item.0 > 0{
            zeroBounds.append((item.0, values.count))
        }
        
        for zb in zeroBounds{
            if zb.1 == values.count{
                // end bound
                for i in (zb.0+1)..<zb.1{
                    result.append((index: i, values[zb.0]))
                }
            }else{
                let gap: Double = (values[zb.1] - values[zb.0]) / Double(zb.1 - zb.0)
                var multiple: Double = 1.0
                for i in (zb.0+1)..<zb.1{
                    result.append((index: i, value: values[zb.0] + gap * multiple))
                    multiple += 1.0
                }
            }
        }
        
        return result
    }
    
    // currently returns first / last item if outside range
    //this orders array of values based on x.
    func linearInterpolate(forX x: Double, fromValues values: [(x: Double, y: Double)]) -> Double{
        let orderedArray = values.sorted(by: {$0.x < $1.x})
        let count = orderedArray.count
        
        if count == 0 { return 0.0 }
        
        if x <= orderedArray[0].x{
            return orderedArray[0].y
        }
        
        if x >= orderedArray[count-1].x{
            return orderedArray[count-1].y
        }
        
        
        var index = 0
        
        findPoint: while (index < count){
            if x <= orderedArray[index].x{
                break findPoint
            }
            index += 1
        }
        
        
        let xGap = orderedArray[index].x - orderedArray[index-1].x
        let yGap = orderedArray[index].y - orderedArray[index-1].y
        
        let xProportion = (x - orderedArray[index-1].x) / xGap
        
        let result =  orderedArray[index-1].y + xProportion * yGap
        return result
    }
    
    func standardDeviation(_ array: [Double]) -> Double{
        return stdDevMeanTotal(array).stdDev
    }
    
    // this is mean / stdDev
    func monotony(_ array: [Double]) -> Double{
        let r = stdDevMeanTotal(array)
        if r.stdDev == 0.0{
            return 0.0
        }
        return r.mean / r.stdDev
        
    }
    
    func strain(_ array: [Double]) -> Double{
        let r = stdDevMeanTotal(array)
        if r.stdDev == 0.0{
            return 0.0
        }
        return r.mean * r.total / r.stdDev
    }
    
    func monotonyAndStrain(_ array: [Double]) -> (monotony: Double, strain: Double){
        let r = stdDevMeanTotal(array)
        var monotony: Double = 0.0
        var strain: Double = 0.0
        if r.stdDev > 0.0{
            monotony = r.mean / r.stdDev
            strain = r.mean * r.total / r.stdDev
        }
        return (monotony, strain)
    }
    
    /* Implementation from https://www.johndcook.com/blog/cpp_phi/
     */
    func phi(stdDev: Double) -> Double{
        let a1 =  0.254829592
        let a2 = -0.284496736
        let a3 =  1.421413741
        let a4 = -1.453152027
        let a5 =  1.061405429
        let p  =  0.3275911
        
        // Save the sign of x
        var sign = 1.0
        if (stdDev < 0){ sign = -1 }
        
        let x = abs(stdDev)/sqrt(2.0)
        
        // A&S formula 7.1.26
        let t = 1.0/(1.0 + p*x)
        let y = 1.0 - (((((a5*t + a4)*t) + a3)*t + a2)*t + a1)*t*exp(-x*x)
        
        return 0.5*(1.0 + sign*y)
    }
    
    //Implementation from https://www.johndcook.com/blog/csharp_phi_inverse/
    func  rationalApproximation(_ t: Double) -> Double{
        // Abramowitz and Stegun formula 26.2.23.
        // The absolute value of the error should be less than 4.5 e-4.
        let c = [2.515517, 0.802853, 0.010328]
        let d = [1.432788, 0.189269, 0.001308]
        return t - ((c[2]*t + c[1])*t + c[0]) / (((d[2]*t + d[1])*t + d[0])*t + 1.0)
    }
    
    //Implementation from https://www.johndcook.com/blog/csharp_phi_inverse/
    //this takes a percentile (probability) and returns number of SD from mean
    func normalCDFInverse(_ p: Double) -> Double{
        if (p <= 0.0 || p >= 1.0){
            print("Invalid input argument: \(p)")
        }
        
        // See article above for explanation of this section.
        if (p < 0.5) {
            // F^-1(p) = - G^-1(p)
            return -rationalApproximation( sqrt(-2.0*log(p)) )
        }else{
            // F^-1(p) = G^-1(1-p)
            return rationalApproximation( sqrt(-2.0*log(1.0 - p)) )
        }
    }
    
    
    func testStDev(){
        let testStdDevs = [-3.0, -2.0, -1.0, 0, 1.0, 2.0, 3.0]
        for x in testStdDevs{
            let p = phi(stdDev: x)
            let i = normalCDFInverse(p)
            print("Stddev \(x) -> \(p) -> \(i)")
        }
        
        let d = Date()
        var array: [Double] = []
        for a in 1...10000{
            array.append(Double(a))
            let r = stdDevMeanTotal(array)
            print("Standard dev of integers to \(a) is \(r.stdDev), monotony = \(r.mean / r.stdDev), strain = \(r.mean * r.total / r.stdDev)")
        }
        
        print("Time for 10,000 std dev calc = \(Date().timeIntervalSince(d))s")
        
    }
    
    func testLinearInterpolation(){
        let testArray = [(1.0,1.0),(2.0,2.0),(2.0,2.0),(32.0,32.0),(12.0,12.0),(8.0,8.0),(1.0,1.0),(200.0,200.0),(-4.0,-4.0)]
        let testNumbers = [1.0, 2.0, 199.0, 1.2345, 2000.0, -1000.0, -3.5]
        
        print("TEST ARRAY:")
        print(testArray)
        print("TEST NUMBERS:")
        print(testNumbers)
        
        for t in testNumbers{
            let r = linearInterpolate(forX: t, fromValues: testArray)
            print("\(t) --> \(r)")
        }
        
    }
    
    private func stdDevMeanTotal(_ array: [Double]) -> (stdDev: Double, mean: Double, total: Double){
        let length = Double(array.count)
        let sum = array.reduce(0, {$0 + $1})
        let avg = sum / length
        let sumOfSquaredAvgDiff = array.map { pow($0 - avg, 2.0)}.reduce(0, {$0 + $1})
        let stdDev = sqrt(sumOfSquaredAvgDiff / length)
        return (stdDev, avg, sum)
    }
    
}


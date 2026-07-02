//
//  TestHelpers.swift
//  SwiftDiceTests
//
//  Created by Brian Arnold on 7/3/26.
//  Copyright © 2026 Brian Arnold. All rights reserved.
//

import Testing
import SwiftDice

/// Use a sample size large enough to hit relatively tight ranges of expected mean, min and max values.
let sampleSize = 1024

/// Rolls `rollable` `times` times, asserting each result falls within `range`, and returns
/// aggregate (mean, min, max) for further statistical assertions.
///
/// Testing with a random number generator means:
/// - Tolerance may be wide enough in some cases to not catch all regressions (false positives)
/// - Once in a blue moon, a test may fail just outside of the tolerance (false negatives)
@discardableResult
func rollSample(_ rollable: Rollable, in range: ClosedRange<Int>, times: Int = sampleSize) -> (mean: Double, min: Int, max: Int) {
    var sum = 0
    var minResult = Int.max
    var maxResult = Int.min
    for _ in 0..<times {
        let result = rollable.roll().result
        #expect(range.contains(result), "result \(result) out of expected range \(range)")
        sum += result
        minResult = Swift.min(minResult, result)
        maxResult = Swift.max(maxResult, result)
    }
    return (Double(sum) / Double(times), minResult, maxResult)
}

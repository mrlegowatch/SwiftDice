//
//  DiceTests.swift
//  SwiftDice
//
//  Created by Brian Arnold on 11/12/16.
//  Copyright © 2016-2017 Brian Arnold. All rights reserved.
//

import Testing
import SwiftDice

/// Use a sample size large enough to hit relatively tight ranges of
/// expected mean, min and max values below.
let sampleSize = 1024

/// Consequences of testing with the random number generator are:
///
///  - Tolerance may be wide enough in some cases that they may not catch all regressions (false positives)
///  - Once in a blue moon, tests may fail just outside of the tolerance (false negatives)
///
@Suite("Dice Tests")
struct DiceTests {

    @Test("Create die")
    func createDie() {
        // Test raw value creation matches enums
        let d4 = Die(rawValue: 4)
        #expect(d4 == Die.d4, "d4")
        let d6 = Die(rawValue: 6)
        #expect(d6 == Die.d6, "d6")
        let d8 = Die(rawValue: 8)
        #expect(d8 == Die.d8, "d8")
        let d10 = Die(rawValue: 10)
        #expect(d10 == Die.d10, "d10")
        let d12 = Die(rawValue: 12)
        #expect(d12 == Die.d12, "d12")
        let d20 = Die(rawValue: 20)
        #expect(d20 == Die.d20, "d20")
        let d100 = Die(rawValue: 100)
        #expect(d100 == Die.d100, "Dice %")
    }

    @Test("Create die negative")
    func createDieNegative() {
        // Negative tests: bad raw values and strings
        let badDie = Die(rawValue: 7)
        #expect(badDie == nil, "d7 should be nil")
    }

    @Test("Roll die")
    func rollDie() {
        let die: Die = .d4

        var sum = 0
        var minValue = 0
        var maxValue = 0
        for _ in 0 ..< sampleSize {
            let roll = die.roll()
            #expect((1...4).contains(roll), "rolling d4, got \(roll)")
            sum += roll
            minValue = minValue == 0 ? roll : min(minValue, roll)
            maxValue = maxValue == 0 ? roll : max(maxValue, roll)

        }
        let mean = Double(sum)/Double(sampleSize)
        #expect((2.0...3.0).contains(mean), "expected mean around 2.5, got \(mean)")

        #expect(minValue == 1, "min value")
        #expect(maxValue == 4, "max value")

        #expect(Die.d4.description == "d4", "d4 description")
    }

    @Test("Dice d12")
    func diceD12() {
        let dice = Dice(.d12)

        var sum = 0
        var minValue = 0
        var maxValue = 0
        for _ in 0 ..< sampleSize {
            let roll = dice.roll().result
            #expect((1...12).contains(roll), "rolling d12, got \(roll)")
            sum += roll
            minValue = minValue == 0 ? roll : min(minValue, roll)
            maxValue = maxValue == 0 ? roll : max(maxValue, roll)
        }
        let mean = Double(sum)/Double(sampleSize)
        #expect((6.0...7.0).contains(mean), "expected mean around 6.5, got \(mean)")

        // TODO: Because 2x produces a bell curve, the actual min/max may be harder to get in a sample
        #expect(minValue <= 1, "min value")
        #expect(maxValue >= 12, "max value")

        #expect(dice.sides == 12, "sides")
        #expect("\(dice.description)" == "d12", "description")
    }

    @Test("Dice 2d8")
    func dice2d8() {
        let dice = Dice(.d8, times: 2)

        var sum = 0
        var minValue = 0
        var maxValue = 0
        for _ in 0 ..< sampleSize {
            let roll = dice.roll().result
            #expect((2...16).contains(roll), "rolling 2d8, got \(roll)")
            sum += roll
            minValue = minValue == 0 ? roll : min(minValue, roll)
            maxValue = maxValue == 0 ? roll : max(maxValue, roll)
        }
        let mean = Double(sum)/Double(sampleSize)
        #expect((7.5...9.5).contains(mean), "expected mean around 8.5, got \(mean)")

        // TODO: Because 2x produces a bell curve, the actual min/max may be harder to get in a sample
        #expect(minValue == 2, "min value")
        #expect(maxValue == 16, "max value")

        #expect(dice.sides == 8, "sides")
        #expect("\(dice.description)" == "2d8", "description")
    }

    @Test("Dropping dice lowest")
    func droppingDiceLowest() {
        let dice = DroppingDice(.d6, times: 4, drop: .lowest)

        var sum = 0
        var minValue = 0
        var maxValue = 0
        for _ in 0 ..< sampleSize {
            let roll = dice.roll().result
            #expect((3...18).contains(roll), "rolling 4d6-L, got \(roll)")
            sum += roll
            minValue = minValue == 0 ? roll : min(minValue, roll)
            maxValue = maxValue == 0 ? roll : max(maxValue, roll)
        }
        let mean = Double(sum)/Double(sampleSize)
        #expect((11.0...13.5).contains(mean), "expected mean around 12.25, got \(mean)")

        // TODO: Because 4x-L produces a sharp bell curve, the actual min/max may be harder to get in a sample
        #expect(minValue <= 5, "min value")
        #expect(maxValue >= 16, "max value")

        #expect(dice.sides == 6, "sides")
        #expect("\(dice.description)" == "4d6-L", "description")

        // TODO: verify that it is actually dropping the lowest score.
    }

    @Test("Dropping dice highest")
    func droppingDiceHighest() {
        let dice = DroppingDice(.d4, times: 3, drop: .highest)

        var sum = 0
        var minValue = 0
        var maxValue = 0
        for _ in 0 ..< sampleSize {
            let roll = dice.roll().result
            #expect((2...8).contains(roll), "rolling 3d4-H, got \(roll)")
            sum += roll
            minValue = minValue == 0 ? roll : min(minValue, roll)
            maxValue = maxValue == 0 ? roll : max(maxValue, roll)
        }
        let mean = Double(sum)/Double(sampleSize)
        #expect((3.7...4.3).contains(mean), "expected mean around 4, got \(mean)")

        #expect(minValue == 2, "min value")
        #expect(maxValue == 8, "max value")

        #expect(dice.sides == 4, "sides")
        #expect("\(dice.description)" == "3d4-H", "description")

        // TODO: verify that it is actually dropping the highest score.
    }

    @Test("Compound dice with modifier")
    func compoundDiceWithModifier() {
        let compoundDice = CompoundDice(.d8, times: 2, modifier: 4)

        var sum = 0
        var minValue = 0
        var maxValue = 0
        for _ in 0 ..< sampleSize {
            let roll = compoundDice.roll().result
            #expect((6...20).contains(roll), "rolling 2d8+4, got \(roll)")
            sum += roll
            minValue = minValue == 0 ? roll : min(minValue, roll)
            maxValue = maxValue == 0 ? roll : max(maxValue, roll)
        }
        let mean = Double(sum)/Double(sampleSize)
        #expect((12.0...14.0).contains(mean), "expected mean around 13.0, got \(mean)")

        #expect(minValue == 6, "min value")
        #expect(maxValue == 20, "max value")

        #expect("\(compoundDice.description)" == "2d8+4", "description")
    }

    @Test("Dice static shorthands")
    func diceStaticShorthands() {
        #expect(Dice.d4.sides == 4)
        #expect(Dice.d6.sides == 6)
        #expect(Dice.d8.sides == 8)
        #expect(Dice.d10.sides == 10)
        #expect(Dice.d12.sides == 12)
        #expect(Dice.d20.sides == 20)
        #expect(Dice.d100.sides == 100)
        #expect(Dice.d4.description == "d4")
        #expect(Dice.d100.description == "d%")
    }

    @Test("Multiplication operator")
    func multiplicationOperator() {
        let dice = 2 * Dice.d8
        #expect(dice.sides == 8)
        #expect(dice.description == "2d8")
    }

    @Test("Addition operator with modifier")
    func additionOperatorWithModifier() {
        let dice = 2 * Dice.d8 + 4
        #expect(dice.description == "2d8+4")
        let roll = dice.roll()
        #expect((6...20).contains(roll.result))
    }

    @Test("Subtraction operator with modifier")
    func subtractionOperatorWithModifier() {
        let dice = Dice.d12 - 2
        #expect(dice.description == "d12-2")
        let roll = dice.roll()
        #expect((-1...10).contains(roll.result))
    }

    @Test("Addition operator with dice")
    func additionOperatorWithDice() {
        let dice = 2 * Dice.d8 + Dice.d4
        #expect(dice.description == "2d8+d4")
    }

    @Test("Dropping method lowest")
    func droppingMethodLowest() {
        let dice = (4 * Dice.d6).dropping(.lowest)
        #expect(dice.sides == 6)
        #expect(dice.description == "4d6-L")
        let roll = dice.roll()
        #expect((3...18).contains(roll.result))
    }

    @Test("Dropping method highest")
    func droppingMethodHighest() {
        let dice = (3 * Dice.d4).dropping(.highest)
        #expect(dice.sides == 4)
        #expect(dice.description == "3d4-H")
    }

    @Test("Compound dice with dice")
    func compoundDiceWithDice() {
        let compoundDice = CompoundDice(lhs: Dice(.d8, times: 2), rhs: Dice(.d4), mathOperator: .add)
        var sum = 0
        var minValue = 0
        var maxValue = 0
        for _ in 0 ..< sampleSize {
            let roll = compoundDice.roll().result
            #expect((3...20).contains(roll), "rolling 2d8+d4, got \(roll)")
            sum += roll
            minValue = minValue == 0 ? roll : min(minValue, roll)
            maxValue = maxValue == 0 ? roll : max(maxValue, roll)
        }
        let mean = Double(sum)/Double(sampleSize)
        #expect((11.0...12.0).contains(mean), "expected mean around 11.5, got \(mean)")

        #expect(minValue <= 4, "min value")
        #expect(maxValue >= 19, "max value")

        #expect("\(compoundDice.description)" == "2d8+d4", "description")
    }
}

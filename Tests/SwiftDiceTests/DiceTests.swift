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

    @Test("Dice d12")
    func diceD12() {
        let dice = Dice.d12

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

        #expect(minValue <= 1, "min value")
        #expect(maxValue >= 12, "max value")

        #expect(dice.sides == 12, "sides")
        #expect("\(dice.description)" == "d12", "description")
    }

    @Test("Dice 2d8")
    func dice2d8() {
        let dice = 2 * Dice.d8

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

        #expect(minValue == 2, "min value")
        #expect(maxValue == 16, "max value")

        #expect(dice.sides == 8, "sides")
        #expect("\(dice.description)" == "2d8", "description")
    }

    @Test("Dropping dice lowest")
    func droppingDiceLowest() {
        let dice = (4 * Dice.d6).dropping(.lowest)

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

        #expect(minValue <= 5, "min value")
        #expect(maxValue >= 16, "max value")

        #expect(dice.sides == 6, "sides")
        #expect("\(dice.description)" == "4d6-L", "description")
    }

    @Test("Dropping dice highest")
    func droppingDiceHighest() {
        let dice = (3 * Dice.d4).dropping(.highest)

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
    }

    @Test("Compound dice with modifier")
    func compoundDiceWithModifier() {
        let compoundDice = 2 * Dice.d8 + 4

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

    @Test("Custom die sides")
    func customDieSides() {
        let d16 = Dice(sides: 16)
        #expect(d16.sides == 16)
        #expect(d16.description == "d16")
        let roll = d16.roll()
        #expect((1...16).contains(roll.result))
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
        let dice = 2 * .d8 + .d4
        #expect(dice.description == "2d8+d4")
        for _ in 0..<sampleSize {
            #expect((3...20).contains(dice.roll().result))
        }
    }

    @Test("Subtraction operator with dice")
    func subtractionOperatorWithDice() {
        let dice = 2 * .d8 - .d4
        #expect(dice.description == "2d8-d4")
        for _ in 0..<sampleSize {
            #expect((-2...15).contains(dice.roll().result))
        }
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
        let compoundDice = 2 * Dice.d8 + Dice.d4
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

    @Test("FudgeDice single")
    func fudgeDiceSingle() {
        let dice = FudgeDice.dF
        #expect(dice.times == 1)
        #expect(dice.description == "dF")
        for _ in 0..<sampleSize {
            #expect((-1...1).contains(dice.roll().result))
        }
    }

    @Test("FudgeDice multiple")
    func fudgeDiceMultiple() {
        let dice = 4 * FudgeDice.dF
        #expect(dice.times == 4)
        #expect(dice.description == "4dF")
        for _ in 0..<sampleSize {
            #expect((-4...4).contains(dice.roll().result))
        }
    }

    @Test("FudgeDice with modifier")
    func fudgeDiceWithModifier() {
        let dice = FudgeDice.dF + 3
        #expect(dice.description == "dF+3")
    }

    @Test("Addition operator with FudgeDice")
    func additionOperatorWithFudgeDice() {
        let dice = 2 * .d8 + .dF
        #expect(dice.description == "2d8+dF")
        for _ in 0..<sampleSize {
            #expect((1...17).contains(dice.roll().result))
        }
    }

    @Test("Subtraction operator with FudgeDice")
    func subtractionOperatorWithFudgeDice() {
        let dice = 2 * .d8 - .dF
        #expect(dice.description == "2d8-dF")
        for _ in 0..<sampleSize {
            #expect((1...17).contains(dice.roll().result))
        }
    }
}

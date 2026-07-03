//
//  DiceTests.swift
//  SwiftDice
//
//  Created by Brian Arnold on 11/12/16.
//  Copyright © 2016-2017 Brian Arnold. All rights reserved.
//

import Testing
import SwiftDice

@Suite("Dice Tests")
struct DiceTests {

    @Test("Dice d12")
    func diceD12() {
        let dice = Dice.d12
        let sample = rollSample(dice, in: 1...12)
        #expect((6.0...7.0).contains(sample.mean), "expected mean around 6.5, got \(sample.mean)")
        #expect(sample.min <= 1)
        #expect(sample.max >= 12)
        #expect(dice.sides == 12)
        #expect(dice.description == "d12")
    }

    @Test("Dice 2d8")
    func dice2d8() {
        let dice = 2 * Dice.d8
        let sample = rollSample(dice, in: 2...16)
        #expect((7.5...9.5).contains(sample.mean), "expected mean around 8.5, got \(sample.mean)")
        #expect(sample.min == 2)
        #expect(sample.max == 16)
        #expect(dice.sides == 8)
        #expect(dice.description == "2d8")
    }

    @Test("Dropping dice lowest")
    func droppingDiceLowest() {
        let dice = (4 * Dice.d6).dropping(.lowest)
        let sample = rollSample(dice, in: 3...18)
        #expect((11.0...13.5).contains(sample.mean), "expected mean around 12.25, got \(sample.mean)")
        #expect(sample.min <= 5)
        #expect(sample.max >= 16)
        #expect(dice.sides == 6)
        #expect(dice.description == "4d6-L")
    }

    @Test("Dropping dice highest")
    func droppingDiceHighest() {
        let dice = (3 * Dice.d4).dropping(.highest)
        let sample = rollSample(dice, in: 2...8)
        #expect((3.7...4.3).contains(sample.mean), "expected mean around 4, got \(sample.mean)")
        #expect(sample.min == 2)
        #expect(sample.max == 8)
        #expect(dice.sides == 4)
        #expect(dice.description == "3d4-H")
    }

    @Test("Compound dice with modifier")
    func compoundDiceWithModifier() {
        let dice = 2 * Dice.d8 + 4
        let sample = rollSample(dice, in: 6...20)
        #expect((12.0...14.0).contains(sample.mean), "expected mean around 13.0, got \(sample.mean)")
        #expect(sample.min == 6)
        #expect(sample.max == 20)
        #expect(dice.description == "2d8+4")
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

    @Test("Multiply operator with modifier")
    func multiplyOperatorWithModifier() {
        let dice = 5 * .d4 * 10
        #expect(dice.description == "5d4x10")
        rollSample(dice, in: 50...200)
    }

    @Test("Divide operator with modifier")
    func divideOperatorWithModifier() {
        let dice = Dice.d100 / 10
        #expect(dice.description == "d%/10")
        rollSample(dice, in: 0...10)
    }

    @Test("Addition operator with dice")
    func additionOperatorWithDice() {
        let dice = 2 * .d8 + .d4
        #expect(dice.description == "2d8+d4")
        rollSample(dice, in: 3...20)
    }

    @Test("Subtraction operator with dice")
    func subtractionOperatorWithDice() {
        let dice = 2 * .d8 - .d4
        #expect(dice.description == "2d8-d4")
        rollSample(dice, in: -2...15)
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

    @Test("Dropping dice lowest two")
    func droppingDiceLowestTwo() {
        let dice = (5 * Dice.d6).dropping(2, .lowest)
        #expect(dice.sides == 6)
        #expect(dice.description == "5d6-L2")
        rollSample(dice, in: 3...18)
    }

    @Test("Dropping method highest two")
    func droppingMethodHighestTwo() {
        let dice = (5 * Dice.d4).dropping(2, .highest)
        #expect(dice.sides == 4)
        #expect(dice.description == "5d4-H2")
        rollSample(dice, in: 3...12)
    }

    @Test("Keeping highest (advantage)")
    func keepingHighest() {
        let dice = (2 * Dice.d20).keeping(.highest)
        #expect(dice.sides == 20)
        #expect(dice.description == "2d20kh1")
        rollSample(dice, in: 1...20)
    }

    @Test("Keeping count highest")
    func keepingCountHighest() {
        let dice = (4 * Dice.d6).keeping(3, .highest)
        #expect(dice.sides == 6)
        #expect(dice.description == "4d6kh3")
        rollSample(dice, in: 3...18)
    }

    @Test("Exploding dice description")
    func explodingDiceDescription() {
        #expect(Dice.d6.exploding.description == "d6!")
        #expect((2 * Dice.d6).exploding.description == "2d6!")
        #expect((2 * .d6.exploding).description == "2d6!")
    }

    @Test("Exploding dice rolls at least one")
    func explodingDiceRolls() {
        let dice = Dice.d6.exploding
        for _ in 0..<sampleSize {
            #expect(dice.roll().result >= 1)
        }
    }

    @Test("Exploding dice with dropping")
    func explodingDiceWithDropping() {
        let dice = (2 * Dice.d6).exploding.dropping(.lowest)
        #expect(dice.description == "2d6!-L")
        for _ in 0..<sampleSize {
            #expect(dice.roll().result >= 1)
        }
    }

    @Test("Rerolling dice description")
    func rerollingDiceDescription() {
        #expect(Dice.d6.rerolling(below: 1).description == "d6r1")
        #expect((4 * Dice.d6).rerolling(below: 2).description == "4d6r2")
        #expect((2 * .d6.rerolling(below: 1)).description == "2d6r1")
    }

    @Test("Rerolling dice rolls in range")
    func rerollingDiceRolls() {
        rollSample(Dice.d6.rerolling(below: 1), in: 1...6)
    }

    @Test("Rerolling dice with dropping")
    func rerollingDiceWithDropping() {
        let dice = (4 * Dice.d6).rerolling(below: 1).dropping(.lowest)
        #expect(dice.description == "4d6r1-L")
        rollSample(dice, in: 3...18)
    }

    @Test("Rerolling and exploding dice")
    func rerollingAndExplodingDice() {
        let dice = Dice.d6.rerolling(below: 1).exploding
        #expect(dice.description == "d6!r1")
        for _ in 0..<sampleSize {
            #expect(dice.roll().result >= 1)
        }
    }

    @Test("Compound dice with dice")
    func compoundDiceWithDice() {
        let dice = 2 * Dice.d8 + Dice.d4
        let sample = rollSample(dice, in: 3...20)
        #expect((11.0...12.0).contains(sample.mean), "expected mean around 11.5, got \(sample.mean)")
        #expect(sample.min <= 4)
        #expect(sample.max >= 19)
        #expect(dice.description == "2d8+d4")
    }

    // Client-side success pool built on rollAll() — demonstrates the extension point
    // for pool mechanics without requiring library support for a specific system's rules.
    private struct SuccessPool {
        let dice: Dice
        let threshold: Int
        func roll() -> Int { dice.rollAll().filter { $0 >= threshold }.count }
    }

    @Test("Success pool via rollAll (client-side example)")
    func successPool() {
        let pool = SuccessPool(dice: 5 * .d10, threshold: 6)
        for _ in 0..<sampleSize {
            #expect((0...5).contains(pool.roll()))
        }
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
        rollSample(dice, in: 1...17)
    }

    @Test("Subtraction operator with FudgeDice")
    func subtractionOperatorWithFudgeDice() {
        let dice = 2 * .d8 - .dF
        #expect(dice.description == "2d8-dF")
        rollSample(dice, in: 1...17)
    }
}

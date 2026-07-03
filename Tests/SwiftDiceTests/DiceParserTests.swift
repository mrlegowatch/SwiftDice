//
//  DiceParserTests.swift
//  RolePlayingCoreTests
//
//  Created by Brian Arnold on 7/2/17.
//  Copyright © 2017 Brian Arnold. All rights reserved.
//

import Testing
import SwiftDice

@Suite("Dice Parser Tests")
struct DiceParserTests {

    let parser = DiceParser()

    @Test("Dice format string")
    func diceFormatString() throws {
        let dice = try parser.parse("d12")
        #expect(dice.description == "d12")
        let sample = rollSample(dice, in: 1...12)
        #expect((6.0...7.0).contains(sample.mean), "expected mean around 6.5, got \(sample.mean)")
        #expect(sample.min == 1)
        #expect(sample.max == 12)
    }

    // Tests both lowercase and uppercase 'd'; both should normalize to "2d10".
    @Test("Dice times string", arguments: ["2d10", "2D10"])
    func diceTimesString(formatString: String) throws {
        let dice = try parser.parse(formatString)
        #expect(dice.description == "2d10")
        let sample = rollSample(dice, in: 2...20)
        #expect((10.0...12.0).contains(sample.mean), "expected mean around 11.0, got \(sample.mean)")
        // 2d10 produces a bell curve; absolute min/max need a wider tolerance for the sample size
        #expect(sample.min <= 3)
        #expect(sample.max >= 19)
    }

    @Test("Dice add modifier")
    func diceAddModifier() throws {
        let dice = try parser.parse("1d20+4")
        #expect(dice.description == "d20+4")  // leading 1 is elided
        let sample = rollSample(dice, in: 5...24)
        #expect((13.0...16.0).contains(sample.mean), "expected mean around 14.5, got \(sample.mean)")
        #expect(sample.min == 5)
        #expect(sample.max == 24)
    }

    @Test("Dice percent")
    func dicePercent() throws {
        let dice = try parser.parse("d%")
        #expect(dice.description == "d%")
        let sample = rollSample(dice, in: 1...100)
        #expect((45.0...56.0).contains(sample.mean), "expected mean around 50.5, got \(sample.mean)")
        // With such a big range, absolute min/max may not be hit within the sample size
        #expect(sample.min <= 2)
        #expect(sample.max >= 99)
    }

    @Test("Multiply with X")
    func multiplyWithX() throws {
        let dice = try parser.parse("2d4x10")
        #expect(dice.description == "2d4x10")
        let sample = rollSample(dice, in: 20...80)
        #expect((46.0...56.0).contains(sample.mean), "expected mean around 50.0, got \(sample.mean)")
        #expect(sample.min == 20)
        #expect(sample.max == 80)
    }

    @Test("Multiply with asterisk")
    func multiplyWithAsterisk() throws {
        let dice = try parser.parse("2d4*10")
        #expect(dice.description == "2d4x10")  // * normalizes to x
        let sample = rollSample(dice, in: 20...80)
        #expect((46.0...56.0).contains(sample.mean), "expected mean around 50.0, got \(sample.mean)")
        #expect(sample.min == 20)
        #expect(sample.max == 80)
    }

    @Test("Divide")
    func divide() throws {
        let dice = try parser.parse("d100/10")
        #expect(dice.description == "d%/10")  // d100 normalizes to d%
        let sample = rollSample(dice, in: 0...10)
        #expect((4.0...5.0).contains(sample.mean), "expected mean around 4.5, got \(sample.mean)")
    }

    @Test("Dropping lowest")
    func droppingLowest() throws {
        let dice = try parser.parse("4d6-L")
        #expect(dice.description == "4d6-L")
        let sample = rollSample(dice, in: 3...18)
        #expect((11.0...13.5).contains(sample.mean), "expected mean around 12.25, got \(sample.mean)")
        // 4d6-L produces a sharp bell curve; absolute min/max need a wider tolerance
        #expect(sample.min <= 5)
        #expect(sample.max >= 16)
    }

    @Test("Complex dice format string")
    func complexDiceFormatString() throws {
        let dice = try parser.parse("2d4+3d12-4")
        #expect(dice.description == "2d4+3d12-4")
        let sample = rollSample(dice, in: 1...40)
        #expect((19.0...22.0).contains(sample.mean), "expected mean around 20.5, got \(sample.mean)")
        // Sharp bell curve; absolute min/max need a wider tolerance
        #expect(sample.min <= 7)
        #expect(sample.max >= 34)
    }

    @Test("Complex dice operator precedence")
    func complexDiceOperatorPrecedence() throws {
        let dice = try parser.parse("2d4+d12-2+5")
        #expect(dice.description == "2d4+d12-2+5")
        let sample = rollSample(dice, in: 6...23)
        #expect((13.0...16.0).contains(sample.mean), "expected mean around 14.5, got \(sample.mean)")
        // Bell curve; absolute min/max need a wider tolerance
        #expect(sample.min <= 7)
        #expect(sample.max >= 22)
    }

    @Test("Complex dice with whitespace and dropping")
    func complexDiceExtraRollDroppingWithWhitespace() throws {
        let dice = try parser.parse("3d4- L + d12 -\n2 + 5")
        #expect(dice.description == "3d4-L+d12-2+5")
        let sample = rollSample(dice, in: 6...23)
        #expect((13.0...16.0).contains(sample.mean), "expected mean around 14.5, got \(sample.mean)")
        // Bell curve; absolute min/max need a wider tolerance
        #expect(sample.min <= 7)
        #expect(sample.max >= 22)
    }

    @Test("Constant modifiers")
    func constantModifiers() throws {
        let dice = try parser.parse("1+3")
        #expect(dice.description == "1+3")
        #expect(dice.roll().description == "1 + 3")
    }

    @Test("Custom die sides")
    func customDieSidesString() throws {
        let dice = try parser.parse("d7")
        #expect(dice.description == "d7")
    }

    @Test("Fudge dice string")
    func fudgeDiceString() throws {
        let dice = try parser.parse("dF")
        #expect(dice.description == "dF")
    }

    @Test("Fudge dice times string")
    func fudgeDiceTimesString() throws {
        let dice = try parser.parse("4dF")
        #expect(dice.description == "4dF")
        rollSample(dice, in: -4...4)
    }

    @Test("Fudge dice with modifier string")
    func fudgeDiceWithModifierString() throws {
        let dice = try parser.parse("dF+2")
        #expect(dice.description == "dF+2")
    }

    @Test("Dropping lowest two")
    func droppingLowestTwo() throws {
        let dice = try parser.parse("4d6-L2")
        #expect(dice.description == "4d6-L2")
        rollSample(dice, in: 2...12)
    }

    @Test("Dropping highest two")
    func droppingHighestTwo() throws {
        let dice = try parser.parse("5d6-H2")
        #expect(dice.description == "5d6-H2")
        rollSample(dice, in: 3...18)
    }

    @Test("Rerolling dice string")
    func rerollingDiceString() throws {
        let dice = try parser.parse("2d6r1")
        #expect(dice.description == "2d6r1")
        rollSample(dice, in: 2...12)
    }

    @Test("Rerolling dice with dropping")
    func rerollingDiceWithDropping() throws {
        let dice = try parser.parse("4d6r1-L")
        #expect(dice.description == "4d6r1-L")
        rollSample(dice, in: 3...18)
    }

    @Test("Rerolling and exploding dice string")
    func rerollingAndExplodingDiceString() throws {
        let dice = try parser.parse("2d6!r1")
        #expect(dice.description == "2d6!r1")
    }

    @Test("Exploding dice string")
    func explodingDiceString() throws {
        let dice = try parser.parse("d6!")
        #expect(dice.description == "d6!")
        for _ in 0..<sampleSize {
            #expect(dice.roll().result >= 1)
        }
    }

    @Test("Exploding dice times string")
    func explodingDiceTimesString() throws {
        let dice = try parser.parse("2d6!")
        #expect(dice.description == "2d6!")
        for _ in 0..<sampleSize {
            #expect(dice.roll().result >= 2)
        }
    }

    @Test("Exploding dice with dropping")
    func explodingDiceWithDropping() throws {
        let dice = try parser.parse("4d6!-L")
        #expect(dice.description == "4d6!-L")
        for _ in 0..<sampleSize {
            #expect(dice.roll().result >= 3)
        }
    }

    @Test("Keep highest notation")
    func keepHighestString() throws {
        let dice = try parser.parse("4d6kh3")
        #expect(dice.description == "4d6kh3")
        rollSample(dice, in: 3...18)
    }

    @Test("Keep lowest notation (disadvantage)")
    func keepLowestString() throws {
        let dice = try parser.parse("2d20kl1")
        #expect(dice.description == "2d20kl1")
        rollSample(dice, in: 1...20)
    }

    @Test("Keep highest advantage")
    func keepHighestAdvantage() throws {
        let dice = try parser.parse("2d20kh1")
        #expect(dice.description == "2d20kh1")
    }

    @Test("Invalid dice format strings", arguments: [
        ("dhello", "unsupported dice number"),
        ("2+elephants", "unsupported character tokens"),
        ("3d", "missing dice sides"),
        ("2-", "missing expression"),
        ("2d4H", "dropping missing minus"),
        ("2-H", "dropping missing SimpleDice"),
        ("3 4", "consecutive numbers"),
        ("3++4", "consecutive math operators"),
        ("d4d4", "consecutive dice expressions"),
        ("dd4", "consecutive dice 'd' characters"),
        ("2d4k", "keep missing method character"),
        ("!", "bare exploding without dice"),
        ("2d6r", "reroll without threshold"),
        ("d0", "invalid die sides"),
        ("", "empty expression"),
        ("F", "fudge without preceding die"),
        ("4dFr1", "reroll on fudge dice"),
        ("4dFkh1", "keep on fudge dice"),
        ("d4dF", "consecutive die and fudge"),
    ])
    func invalidDiceFormatStrings(badFormatString: String, reason: String) {
        #expect(throws: DiceParseError.self, "'\(badFormatString)' \(reason)") {
            _ = try parser.parse(badFormatString)
        }
    }

    @Test("Error descriptions are non-nil")
    func errorDescriptions() {
        let errors: [DiceParseError] = [
            .invalidCharacter("?"),
            .invalidDieSides(0),
            .missingMinus,
            .missingSimpleDice,
            .missingDieSides,
            .missingExpression,
            .consecutiveNumbers,
            .consecutiveMathOperators,
            .consecutiveDiceExpressions,
        ]
        for error in errors {
            #expect(error.errorDescription != nil, "errorDescription should not be nil for \(error)")
        }
    }
}

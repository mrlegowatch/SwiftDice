//
//  Dice.swift
//  SwiftDice
//
//  Created by Brian Arnold on 3/22/17.
//  Copyright © 2017 Brian Arnold. All rights reserved.
//


/// A dice expression with a given number of sides, rolled one or more times.
public struct Dice: Rollable {
    public let sides: Int
    public let times: Int

    /// Creates a Dice with the specified number of sides. Optionally specify times to roll.
    /// Defaults to rolling one time.
    public init(sides: Int, times: Int = 1) {
        self.sides = sides
        self.times = times
    }

    /// Rolls the specified number of times, returning the array of rolls.
    internal func rollAll() -> [Int] {
        return (0..<times).map { _ in Int.random(in: 1...sides) }
    }

    /// Rolls the specified number of times, returning the sum of the rolls and a description.
    public func roll() -> DiceRoll {
        let lastRoll = rollAll()
        let result = lastRoll.reduce(0, +)
        return DiceRoll(result, rollDescription(lastRoll))
    }

    /// Returns a description, "[<times>]d<sides>"; times is left out if it is 1.
    /// d100 is rendered as "d%".
    public var description: String {
        let timesString = times == 1 ? "" : "\(times)"
        let sidesString = sides == 100 ? "%" : "\(sides)"
        return "\(timesString)d\(sidesString)"
    }

    /// Returns the last roll as a sequence of added numbers in parenthesis.
    internal func rollDescription(_ lastRoll: [Int]) -> String {
        guard !lastRoll.isEmpty else { return "0" }

        guard lastRoll.count > 1 else {
            return "\(lastRoll[0])"
        }

        let rollsString = lastRoll.map(String.init).joined(separator: " + ")
        return "(\(rollsString))"
    }
}

// MARK: - Multiplication Operator

/// Returns a `Dice` rolled the specified number of times.
public func *(lhs: Int, rhs: Dice) -> Dice {
    Dice(sides: rhs.sides, times: lhs)
}

// Named shorthands for the standard polyhedral set. Use these with the `*`
// operator above instead of specifying `times` explicitly.
//
// For dice outside this set, construct directly or add your own shorthands:
//
//     extension Dice {
//         static let d3  = Dice(sides: 3)
//         static let d30 = Dice(sides: 30)
//     }
extension Dice {
    public static let d4   = Dice(sides: 4)
    public static let d6   = Dice(sides: 6)
    public static let d8   = Dice(sides: 8)
    public static let d10  = Dice(sides: 10)
    public static let d12  = Dice(sides: 12)
    public static let d20  = Dice(sides: 20)
    public static let d100 = Dice(sides: 100)
}

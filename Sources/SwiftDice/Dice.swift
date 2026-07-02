//
//  Dice.swift
//  SwiftDice
//
//  Created by Brian Arnold on 3/22/17.
//  Copyright © 2017 Brian Arnold. All rights reserved.
//


/// A dice expression with a single die type rolled one or more times.
public struct Dice: Rollable {
    public let die: Die
    public let times: Int

    /// Creates a Dice for the specified die. Optionally specify times to roll.
    /// Defaults to rolling one time.
    public init(_ die: Die, times: Int = 1) {
        self.die = die
        self.times = times
    }

    /// Rolls the specified number of times, returning the array of rolls.
    internal func rollAll() -> [Int] {
        return die.roll(times)
    }

    /// Rolls the specified number of times, returning the sum of the rolls and a description.
    public func roll() -> DiceRoll {
        let lastRoll = rollAll()
        let result = lastRoll.reduce(0, +)
        let description = rollDescription(lastRoll)
        return DiceRoll(result, description)
    }

    /// Returns the number of dice sides.
    public var sides: Int { die.rawValue }

    /// Returns a description, "[<times>]d<sides>"; times is left out if it is 1.
    public var description: String {
        let timesString = times == 1 ? "" : "\(times)"
        return "\(timesString)\(die)"
    }

    /// Returns the last roll as a sequence of added numbers in parenthesis.
    internal func rollDescription(_ lastRoll: [Int]) -> String {
        guard !lastRoll.isEmpty else { return "0" }

        // Single roll doesn't need parentheses
        guard lastRoll.count > 1 else {
            return "\(lastRoll[0])"
        }

        // Multiple rolls: format as (roll1 + roll2 + ... + rollN)
        let rollsString = lastRoll.map(String.init).joined(separator: " + ")
        return "(\(rollsString))"
    }
}

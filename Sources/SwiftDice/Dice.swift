//
//  Dice.swift
//  SwiftDice
//
//  Created by Brian Arnold on 3/22/17.
//  Copyright © 2017 Brian Arnold. All rights reserved.
//


/// A dice expression with a given number of sides, rolled one or more times.
public struct Dice: Rollable, Equatable {
    public let sides: Int
    public let times: Int
    public let isExploding: Bool
    /// When set, any initial die result at or below this value is rerolled once.
    public let rerollThreshold: Int?

    /// Maximum number of extra rolls allowed per die when exploding.
    private static let maxExplosions = 100

    /// Creates a Dice with the specified number of sides. Optionally specify times to roll,
    /// whether dice explode (reroll and add on a maximum result), and a reroll threshold
    /// (reroll once if the initial result is at or below this value).
    public init(sides: Int, times: Int = 1, exploding: Bool = false, rerollThreshold: Int? = nil) {
        self.sides = sides
        self.times = times
        self.isExploding = exploding
        self.rerollThreshold = rerollThreshold
    }

    /// Returns a copy of this Dice with explosion enabled, preserving all other options.
    public var exploding: Dice {
        Dice(sides: sides, times: times, exploding: true, rerollThreshold: rerollThreshold)
    }

    /// Returns a copy of this Dice that rerolls once any initial result at or below `threshold`,
    /// preserving all other options.
    public func rerolling(below threshold: Int) -> Dice {
        Dice(sides: sides, times: times, exploding: isExploding, rerollThreshold: threshold)
    }

    /// Rolls the specified number of times, returning the array of per-die results.
    /// Reroll (if set) applies to the initial roll only; explosion chains follow.
    /// When exploding, each element is the chain sum for that die position, not individual rolls.
    public func rollAll() -> [Int] {
        (0..<times).map { _ in
            var total = 0
            var lastRoll = 0
            var count = 0
            repeat {
                lastRoll = Int.random(in: 1...sides)
                if count == 0, let threshold = rerollThreshold, lastRoll <= threshold {
                    lastRoll = Int.random(in: 1...sides)
                }
                total += lastRoll
                count += 1
            } while isExploding && lastRoll == sides && count <= Self.maxExplosions
            return total
        }
    }

    /// Rolls the specified number of times, returning the sum of the rolls and a description.
    public func roll() -> DiceRoll {
        let lastRoll = rollAll()
        let result = lastRoll.reduce(0, +)
        return DiceRoll(result, rollDescription(lastRoll))
    }

    /// Returns a description, "[<times>]d<sides>[!][r<threshold>]"; times is left out if 1.
    /// d100 is rendered as "d%".
    public var description: String {
        let timesString = times == 1 ? "" : "\(times)"
        let sidesString = sides == 100 ? "%" : "\(sides)"
        let explodingString = isExploding ? "!" : ""
        let rerollString = rerollThreshold.map { "r\($0)" } ?? ""
        return "\(timesString)d\(sidesString)\(explodingString)\(rerollString)"
    }

}

// MARK: - Multiplication Operator

/// Returns a `Dice` rolled the specified number of times, preserving all roll options.
public func *(lhs: Int, rhs: Dice) -> Dice {
    Dice(sides: rhs.sides, times: lhs, exploding: rhs.isExploding, rerollThreshold: rhs.rerollThreshold)
}

// Named shorthands for the standard polyhedral set. See README for the extension pattern
// to add shorthands for non-standard die sizes (d3, d30, etc.).
extension Dice {
    public static let d4   = Dice(sides: 4)
    public static let d6   = Dice(sides: 6)
    public static let d8   = Dice(sides: 8)
    public static let d10  = Dice(sides: 10)
    public static let d12  = Dice(sides: 12)
    public static let d20  = Dice(sides: 20)
    public static let d100 = Dice(sides: 100)
}

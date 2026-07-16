//
//  Dice.swift
//  SwiftDice
//
//  Created by Brian Arnold on 3/22/17.
//  Copyright © 2017 Brian Arnold. All rights reserved.
//


/// A standard polyhedral die, optionally rolled multiple times, with support for exploding and rerolling.
///
/// Use the static shorthands for the standard polyhedral set, then compose with arithmetic operators:
///
/// ```swift
/// Dice.d6                          // one six-sided die
/// 4 * .d6                          // four six-sided dice
/// (4 * .d6).dropping(.lowest)      // four d6, drop the lowest
/// Dice.d6.exploding                // d6 that explodes on a 6
/// Dice.d6.rerolling(below: 1)      // d6 that rerolls initial 1s once
/// ```
///
/// Use `rollAll()` to get the individual per-die values before they are summed — this enables
/// client-side pool mechanics such as counting successes or applying per-die thresholds.
public struct Dice: Rollable, Equatable {
    public let sides: Int
    public let times: Int
    /// When `true`, a maximum roll triggers an additional roll whose value is added (chains up to 100 times per die).
    public let isExploding: Bool
    /// When set, any initial die result at or below this value is rerolled once.
    public let rerollThreshold: Int?

    /// Maximum number of extra rolls allowed per die when exploding.
    private static let maxExplosions = 100

    /// Creates a `Dice` with the specified number of sides.
    /// - Parameters:
    ///   - sides: The number of sides on each die.
    ///   - times: The number of dice to roll.
    ///   - exploding: When `true`, a maximum result triggers an additional roll whose value is added.
    ///   - rerollThreshold: When set, an initial result at or below this value is rerolled once.
    public init(sides: Int, times: Int = 1, exploding: Bool = false, rerollThreshold: Int? = nil) {
        self.sides = sides
        self.times = times
        self.isExploding = exploding
        self.rerollThreshold = rerollThreshold
    }

    /// A copy of this `Dice` with explosion enabled, preserving all other options.
    public var exploding: Dice {
        Dice(sides: sides, times: times, exploding: true, rerollThreshold: rerollThreshold)
    }

    /// Returns a copy of this `Dice` that rerolls once any initial result at or below `threshold`.
    /// - Parameter threshold: Results at or below this value are rerolled once.
    /// - Returns: A copy of this `Dice` with the reroll threshold set, preserving all other options.
    public func rerolling(below threshold: Int) -> Dice {
        Dice(sides: sides, times: times, exploding: isExploding, rerollThreshold: threshold)
    }

    /// Rolls each die independently and returns the per-die results without summing.
    ///
    /// Reroll (if set) applies to the initial roll only; explosion chains follow.
    /// When exploding, each element is the chain sum for that die position, not individual rolls.
    /// - Returns: An array of per-die results; use `roll()` to get the aggregate sum.
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

    /// Rolls all dice and returns the sum with a description of each value.
    /// - Returns: A `DiceRoll` with `result` as the sum and `description` showing each die's value.
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

/// Returns a `Dice` rolled `lhs` times, preserving all roll options on `rhs`.
/// - Parameters:
///   - lhs: The number of times to roll.
///   - rhs: The die definition to replicate.
/// - Returns: A `Dice` equivalent to rolling `rhs` `lhs` times.
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

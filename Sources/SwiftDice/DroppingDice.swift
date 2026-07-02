//
//  DroppingDice.swift
//  SwiftDice
//
//  Created by Brian Arnold on 3/22/17.
//  Copyright © 2017 Brian Arnold. All rights reserved.
//


/// A dropping dice is an extension of Dice that drops the highest or lowest roll.
/// This is done through composition, instead of subclassing.
public struct DroppingDice: Rollable {
    public let dice: Dice

    /// Options to drop the lowest or highest roll.
    public enum Drop: String, CaseIterable, Sendable {
        case lowest = "L"
        case highest = "H"
    }

    /// Whether to drop the lowest or highest roll.
    public let drop: Drop

    /// Creates a Dice for the specified die, times to roll,
    /// and whether to drop the high or low result.
    public init(_ die: Die, times: Int, drop: Drop) {
        self.init(Dice(die, times: times), drop: drop)
    }

    /// Wraps a Dice with whether to drop the high or low result.
    public init(_ dice: Dice, drop: Drop) {
        self.dice = dice
        self.drop = drop
    }

    /// Returns the number of dice sides.
    public var sides: Int { dice.sides }

    /// Rolls the specified number of times, returning the sum of the rolls,
    /// minus the dropped roll. The intermediate rolls, including the dropped roll,
    /// can be inspected in dice.lastRoll.
    public func roll() -> DiceRoll {
        let lastRoll = dice.rollAll()

        guard let droppedRoll = drop == .lowest ? lastRoll.min() : lastRoll.max() else {
            // Edge case: no rolls to drop (shouldn't happen in practice)
            return DiceRoll(0, "(0)")
        }

        let result = lastRoll.reduce(0, +) - droppedRoll
        let description = "(\(dice.rollDescription(lastRoll)) - \(droppedRoll))"

        return DiceRoll(result, description)
    }

    /// Returns a description of the dice, with "-L" or "-H" appended.
    public var description: String {
        return "\(dice)-\(drop.rawValue)"
    }
}

extension Dice {
    /// Convenience to make code using DroppingDice more readable.
    public func dropping(_ drop: DroppingDice.Drop) -> DroppingDice {
        DroppingDice(self, drop: drop)
    }
}

//
//  DiceRoll.swift
//  SwiftDice
//
//  Created by Brian Arnold on 10/15/18.
//  Copyright © 2018 Brian Arnold. All rights reserved.
//

/// The outcome of a single `roll()` call, pairing the numeric total with a breakdown of individual values.
///
/// Use `result` for game logic and `description` for display:
///
/// ```swift
/// let roll = (4 * .d6).dropping(.lowest).roll()
/// roll.result       // e.g. 14  — the integer total after dropping
/// roll.description  // e.g. "(3 + 6 + 4 + 5 - 3)" — shows each die and what was dropped
/// ```
public struct DiceRoll: CustomStringConvertible, Equatable, Sendable {

    /// The result of the roll.
    public let result: Int

    /// A string representing the intermediate values of the dice roll.
    /// For example, a "`3d6`" might return "`(4+1+5)`".
    public let description: String

    /// Creates a roll with its accompanying description of intermediate values.
    /// - Parameters:
    ///   - result: The integer result of the roll.
    ///   - description: A human-readable breakdown of intermediate values (e.g. `"(4 + 2 + 6)"`).
    public init(_ result: Int, _ description: String) {
        self.result = result
        self.description = description
    }
}

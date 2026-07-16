//
//  DiceModifier.swift
//  SwiftDice
//
//  Created by Brian Arnold on 3/22/17.
//  Copyright © 2017 Brian Arnold. All rights reserved.
//


/// A constant integer value that participates as a `Rollable`, used as a modifier in compound expressions.
///
/// `DiceModifier` is the leaf node produced by integer operands in arithmetic dice expressions:
///
/// ```swift
/// 2 * .d8 + 4    // the `4` becomes DiceModifier(4) inside a CompoundDice
/// Dice.d12 - 2   // the `2` becomes DiceModifier(2)
/// ```
///
/// Prefer constructing modifiers via the `+`, `-`, `*`, and `/` operators on `Rollable` rather than directly.
public struct DiceModifier: Rollable, Equatable {
    public let modifier: Int

    /// Creates a constant modifier.
    /// - Parameter modifier: The constant value returned by every `roll()`.
    public init(_ modifier: Int) {
        self.modifier = modifier
    }

    public func roll() -> DiceRoll {
        return DiceRoll(modifier, "\(modifier)")
    }

    public var description: String { "\(modifier)" }
}

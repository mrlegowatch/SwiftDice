//
//  Rollable.swift
//  SwiftDice
//
//  Created by Brian Arnold on 11/12/16.
//  Copyright © 2016 Brian Arnold. All rights reserved.
//


/// The common interface for all dice expressions.
///
/// All concrete dice types — `Dice`, `FudgeDice`, `SelectingDice`, `CompoundDice`, and
/// `DiceModifier` — conform to `Rollable`. Accepting `any Rollable` (or `some Rollable`) lets
/// you store and pass dice expressions without committing to a specific concrete type.
///
/// Conformers also implement `CustomStringConvertible`, returning the standard dice notation
/// string (e.g. `"4d6-L"`, `"2d8+4"`), which `DiceParser` can round-trip back to an
/// equivalent instance.
public protocol Rollable: CustomStringConvertible, Sendable {

    /// Rolls the dice and returns the result.
    /// - Returns: A `DiceRoll` containing the integer result and a description of intermediate values.
    func roll() -> DiceRoll
}

extension Rollable {
    func rollDescription(_ rolls: [Int]) -> String {
        guard !rolls.isEmpty else { return "0" }
        guard rolls.count > 1 else { return "\(rolls[0])" }
        let rollsString = rolls.map(String.init).joined(separator: " + ")
        return "(\(rollsString))"
    }
}

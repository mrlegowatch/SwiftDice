//
//  Rollable.swift
//  SwiftDice
//
//  Created by Brian Arnold on 11/12/16.
//  Copyright © 2016 Brian Arnold. All rights reserved.
//


/// A representation of one or more dice of different sides and combinations.
/// Implementations must conform to the CustomStringConvertible protocol.
public protocol Rollable: CustomStringConvertible, Sendable {

    /// Rolls the dice, and returns the result in a DiceRoll.
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

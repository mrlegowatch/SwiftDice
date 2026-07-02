//
//  Rollable.swift
//  SwiftDice
//
//  Created by Brian Arnold on 11/12/16.
//  Copyright © 2016-2017 Brian Arnold. All rights reserved.
//


/// A representation of one or more dice of different sides and combinations.
/// Implementations must conform to the CustomStringConvertible protocol.
public protocol Rollable: CustomStringConvertible, Sendable {

    /// Rolls the dice, and returns the result in a DiceRoll.
    func roll() -> DiceRoll
}

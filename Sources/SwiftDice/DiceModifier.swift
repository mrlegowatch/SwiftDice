//
//  DiceModifier.swift
//  RolePlayingCore
//
//  Created by Brian Arnold on 3/22/17.
//  Copyright © 2017 Brian Arnold. All rights reserved.
//


/// A constant value that participates as a `Rollable`, used as a modifier in compound expressions.
/// Construct via the `+` or `-` operators on `Rollable` rather than directly.
public struct DiceModifier: Rollable {
    public let modifier: Int

    init(_ modifier: Int) {
        self.modifier = modifier
    }

    public func roll() -> DiceRoll {
        return DiceRoll(modifier, "\(modifier)")
    }

    public var description: String { "\(modifier)" }
}

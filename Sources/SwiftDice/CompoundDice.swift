//
//  CompoundDice.swift
//  SwiftDice
//
//  Created by Brian Arnold on 3/22/17.
//  Copyright © 2017 Brian Arnold. All rights reserved.
//


/// General-purpose composition of dice rolls.
///
/// The two primary use cases for this type are:
/// - combining two rolls, e.g., "`2d4+d6`",
/// - using a modifier, e.g., "`d12+2`".
public struct CompoundDice: Rollable, Equatable {
    public let lhs: Rollable
    public let rhs: Rollable
    public let mathOperator: MathOperator

    /// The arithmetic operators supported between two `Rollable` expressions.
    public enum MathOperator: String, CaseIterable, Sendable {
        case add      = "+"
        case subtract = "-"
        case multiply = "x"
        case divide   = "/"
    }

    /// Creates a dice from two rollable instances with a math operator.
    public init(lhs: Rollable, rhs: Rollable, mathOperator: MathOperator) {
        self.lhs = lhs
        self.rhs = rhs
        self.mathOperator = mathOperator
    }

    /// Rolls the dice on both sides and combines them with the math operator,
    /// returning the result.
    public func roll() -> DiceRoll {
        let lhsRoll = lhs.roll()
        let rhsRoll = rhs.roll()

        let result: Int
        switch mathOperator {
        case .add:      result = lhsRoll.result + rhsRoll.result
        case .subtract: result = lhsRoll.result - rhsRoll.result
        case .multiply: result = lhsRoll.result * rhsRoll.result
        case .divide:   result = lhsRoll.result / rhsRoll.result
        }

        let description = "\(lhsRoll.description) \(mathOperator.rawValue) \(rhsRoll.description)"
        return DiceRoll(result, description)
    }

    /// Returns a description of the left and right hand sides with the math operator.
    public var description: String { "\(lhs)\(mathOperator.rawValue)\(rhs)" }
    
    public static func ==(lhs: CompoundDice, rhs: CompoundDice) -> Bool {
        lhs.description == rhs.description
    }
}

// MARK: - Addition and Subtraction

public func +(lhs: some Rollable, rhs: some Rollable) -> CompoundDice {
    CompoundDice(lhs: lhs, rhs: rhs, mathOperator: .add)
}

public func -(lhs: some Rollable, rhs: some Rollable) -> CompoundDice {
    CompoundDice(lhs: lhs, rhs: rhs, mathOperator: .subtract)
}

// Typed rhs overloads allow leading-dot shorthand: `2 * .d8 + .d4`, `someRollable + .dF`.
// Swift resolves `.d4` / `.dF` because the rhs type is concrete, not a generic placeholder.

public func +(lhs: some Rollable, rhs: Dice) -> CompoundDice {
    CompoundDice(lhs: lhs, rhs: rhs, mathOperator: .add)
}

public func -(lhs: some Rollable, rhs: Dice) -> CompoundDice {
    CompoundDice(lhs: lhs, rhs: rhs, mathOperator: .subtract)
}

public func +(lhs: some Rollable, rhs: FudgeDice) -> CompoundDice {
    CompoundDice(lhs: lhs, rhs: rhs, mathOperator: .add)
}

public func -(lhs: some Rollable, rhs: FudgeDice) -> CompoundDice {
    CompoundDice(lhs: lhs, rhs: rhs, mathOperator: .subtract)
}

public func +(lhs: some Rollable, rhs: Int) -> CompoundDice {
    CompoundDice(lhs: lhs, rhs: DiceModifier(rhs), mathOperator: .add)
}

public func -(lhs: some Rollable, rhs: Int) -> CompoundDice {
    CompoundDice(lhs: lhs, rhs: DiceModifier(rhs), mathOperator: .subtract)
}

// MARK: - Multiplication and Division

// Note: `Int * Dice` (the "times" operator) and `Rollable * Int` have opposite
// parameter order and do not conflict, so `5 * .d4 * 10` evaluates as
// `(5 * .d4) * 10` → CompoundDice with .multiply.

public func *(lhs: some Rollable, rhs: some Rollable) -> CompoundDice {
    CompoundDice(lhs: lhs, rhs: rhs, mathOperator: .multiply)
}

public func /(lhs: some Rollable, rhs: some Rollable) -> CompoundDice {
    CompoundDice(lhs: lhs, rhs: rhs, mathOperator: .divide)
}

public func *(lhs: some Rollable, rhs: Int) -> CompoundDice {
    CompoundDice(lhs: lhs, rhs: DiceModifier(rhs), mathOperator: .multiply)
}

public func /(lhs: some Rollable, rhs: Int) -> CompoundDice {
    CompoundDice(lhs: lhs, rhs: DiceModifier(rhs), mathOperator: .divide)
}

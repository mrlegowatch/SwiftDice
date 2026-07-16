//
//  CompoundDice.swift
//  SwiftDice
//
//  Created by Brian Arnold on 3/22/17.
//  Copyright © 2017 Brian Arnold. All rights reserved.
//


/// A dice expression that combines two `Rollable` operands with an arithmetic operator.
///
/// `CompoundDice` is produced by the arithmetic operators defined on `Rollable`:
///
/// ```swift
/// 2 * .d8 + 4      // "2d8+4"  — two d8 plus a constant
/// 2 * .d8 + .d4    // "2d8+d4" — two d8 plus one d4
/// 5 * .d4 * 10     // "5d4x10" — five d4 multiplied by 10
/// ```
///
/// Both operands are rolled independently on each `roll()` call, so every invocation produces
/// a fresh result for both sides.
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

    /// Creates a compound dice expression from two rollable operands.
    /// - Parameters:
    ///   - lhs: The left-hand operand.
    ///   - rhs: The right-hand operand.
    ///   - mathOperator: The arithmetic operation applied to the two rolled results.
    public init(lhs: Rollable, rhs: Rollable, mathOperator: MathOperator) {
        self.lhs = lhs
        self.rhs = rhs
        self.mathOperator = mathOperator
    }

    /// Rolls both operands and combines their results with `mathOperator`.
    /// - Returns: A `DiceRoll` whose `result` is the combined value and `description` shows both operands.
    public func roll() -> DiceRoll {
        let lhsRoll = lhs.roll()
        let rhsRoll = rhs.roll()

        let result: Int
        switch mathOperator {
        case .add:      result = lhsRoll.result + rhsRoll.result
        case .subtract: result = lhsRoll.result - rhsRoll.result
        case .multiply: result = lhsRoll.result * rhsRoll.result
        case .divide:   result = rhsRoll.result == 0 ? 0 : lhsRoll.result / rhsRoll.result
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

//
//  FudgeDice.swift
//  SwiftDice
//
//  Created by Brian Arnold on 7/3/26.
//  Copyright © 2026 Brian Arnold. All rights reserved.
//

/// A Fudge/FATE die expression that produces outcomes of −1, 0, or +1 per die.
///
/// Fudge dice are commonly used in FATE and Fudge role-playing games. Results range
/// from `[-times, times]`. Use the `dF` shorthand or the `*` operator for multi-die expressions:
///
/// ```swift
/// FudgeDice.dF         // one Fudge die, range -1...1
/// 4 * .dF              // four Fudge dice, range -4...4
/// FudgeDice.dF + 3     // one Fudge die with a +3 modifier
/// ```
public struct FudgeDice: Rollable, Equatable {
    public let times: Int

    /// Creates a Fudge dice expression.
    /// - Parameter times: The number of Fudge dice to roll.
    public init(times: Int = 1) {
        self.times = times
    }

    /// Rolls all Fudge dice and returns the sum.
    /// - Returns: A `DiceRoll` with `result` in the range `[-times, times]`.
    public func roll() -> DiceRoll {
        let rolls = (0..<times).map { _ in Int.random(in: -1...1) }
        let result = rolls.reduce(0, +)
        return DiceRoll(result, rollDescription(rolls))
    }

    public var description: String {
        times == 1 ? "dF" : "\(times)dF"
    }
}

extension FudgeDice {
    public static let dF = FudgeDice()
}

/// Returns a `FudgeDice` rolled `lhs` times.
/// - Parameters:
///   - lhs: The number of times to roll.
///   - rhs: The `FudgeDice` instance (its `times` value is replaced).
/// - Returns: A `FudgeDice` with `times` equal to `lhs`.
public func *(lhs: Int, rhs: FudgeDice) -> FudgeDice {
    FudgeDice(times: lhs)
}

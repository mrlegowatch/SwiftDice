//
//  FudgeDice.swift
//  SwiftDice
//
//  Created by Brian Arnold on 7/3/26.
//  Copyright © 2026 Brian Arnold. All rights reserved.
//

/// A Fudge/FATE die expression, producing outcomes of -1, 0, or +1 per die rolled.
/// Commonly used in FATE and Fudge role-playing games.
public struct FudgeDice: Rollable, Equatable {
    public let times: Int

    public init(times: Int = 1) {
        self.times = times
    }

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

/// Returns a `FudgeDice` rolled the specified number of times.
public func *(lhs: Int, rhs: FudgeDice) -> FudgeDice {
    FudgeDice(times: lhs)
}

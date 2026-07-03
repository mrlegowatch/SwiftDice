//
//  FudgeDice.swift
//  SwiftDice
//

/// A Fudge/FATE die expression, producing outcomes of -1, 0, or +1 per die rolled.
/// Commonly used in FATE and Fudge role-playing games.
public struct FudgeDice: Rollable {
    public let times: Int

    public init(times: Int = 1) {
        self.times = times
    }

    public func roll() -> DiceRoll {
        let rolls = (0..<times).map { _ in Int.random(in: -1...1) }
        let result = rolls.reduce(0, +)
        return DiceRoll(result, rollDescription(rolls))
    }

    private func rollDescription(_ rolls: [Int]) -> String {
        guard !rolls.isEmpty else { return "0" }
        guard rolls.count > 1 else { return "\(rolls[0])" }
        let rollsString = rolls.map(String.init).joined(separator: " + ")
        return "(\(rollsString))"
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

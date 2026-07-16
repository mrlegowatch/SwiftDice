//
//  SelectingDice.swift
//  SwiftDice
//
//  Created by Brian Arnold on 3/22/17.
//  Copyright © 2017 Brian Arnold. All rights reserved.
//


/// A dice pool that rolls multiple dice and sums only a subset, dropping the rest.
///
/// `SelectingDice` models two common tabletop notations — dropping extreme dice, or keeping a
/// specific count — and uses the chosen method when formatting `description`:
///
/// ```swift
/// (4 * .d6).dropping(.lowest)     // "4d6-L"   — roll 4d6, drop the lowest
/// (4 * .d6).keeping(3, .highest)  // "4d6kh3"  — roll 4d6, keep the three highest
/// (2 * .d20).keeping(.highest)    // "2d20kh1" — advantage: roll 2d20, keep the highest
/// ```
///
/// The drop count is clamped to at most `dice.times - 1`, so at least one die is always kept.
/// Construct via the `.dropping(_:)` / `.keeping(_:)` methods on `Dice` rather than directly.
public struct SelectingDice: Rollable, Equatable {
    public let dice: Dice

    /// Describes which end of the distribution to drop and how many dice to drop.
    public struct Selection: Equatable, Sendable {
        /// Whether to drop from the lowest or highest end of the roll distribution.
        public enum Kind: String, CaseIterable, Sendable {
            case lowest  = "L"
            case highest = "H"
        }

        public let kind: Kind
        public let count: Int

        /// Creates a selection describing which dice to drop.
        /// - Parameters:
        ///   - kind: Whether to drop from the lowest or highest end.
        ///   - count: The number of dice to drop.
        public init(kind: Kind, count: Int = 1) {
            self.kind = kind
            self.count = count
        }
    }

    /// Whether this was created via dropping or keeping notation, which determines
    /// the format used by `description`.
    public enum Method: Sendable {
        case dropping
        case keeping
    }

    public let selection: Selection
    public let method: Method

    /// Wraps a `Dice` with a selection describing how many dice to drop and from which end.
    ///
    /// The drop count is clamped to at most `dice.times - 1`, ensuring at least one die is always kept.
    /// - Parameters:
    ///   - dice: The dice pool to roll.
    ///   - selection: Which end to drop and how many.
    ///   - method: Whether to present as dropping or keeping notation in `description`.
    public init(_ dice: Dice, selection: Selection, method: Method = .dropping) {
        self.dice = dice
        let maxDrop = max(0, dice.times - 1)
        self.selection = Selection(kind: selection.kind, count: min(selection.count, maxDrop))
        self.method = method
    }

    public var sides: Int { dice.sides }

    /// Rolls the dice, drops the specified count of lowest or highest results,
    /// and returns the sum of the remaining rolls.
    /// - Returns: A `DiceRoll` with `result` as the sum of kept dice and `description` showing dropped values.
    public func roll() -> DiceRoll {
        let rolls = dice.rollAll()
        let dropCount = min(selection.count, rolls.count)

        let sortedIndices = rolls.indices.sorted { rolls[$0] < rolls[$1] }
        let droppedIndices: Set<Int>
        switch selection.kind {
        case .lowest:  droppedIndices = Set(sortedIndices.prefix(dropCount))
        case .highest: droppedIndices = Set(sortedIndices.suffix(dropCount))
        }

        let kept = rolls.indices.filter { !droppedIndices.contains($0) }.map { rolls[$0] }
        let result = kept.reduce(0, +)

        let droppedValues = droppedIndices.map { rolls[$0] }.sorted()
        let droppedDesc = droppedValues.map { " - \($0)" }.joined()
        let description = "(\(dice.rollDescription(rolls))\(droppedDesc))"

        return DiceRoll(result, description)
    }

    /// The dice notation string matching how this was created.
    /// Dropping mode: `"4d6-L"`, `"5d6-L2"`. Keeping mode: `"4d6kh3"`, `"2d20kh1"`.
    public var description: String {
        switch method {
        case .dropping:
            let countSuffix = selection.count > 1 ? "\(selection.count)" : ""
            return "\(dice)-\(selection.kind.rawValue)\(countSuffix)"
        case .keeping:
            // Invert: dropping lowest = keeping highest (kh); dropping highest = keeping lowest (kl)
            let kindChar = selection.kind == .lowest ? "h" : "l"
            let keepCount = dice.times - selection.count
            return "\(dice)k\(kindChar)\(keepCount)"
        }
    }
}

extension Dice {
    /// Returns a `SelectingDice` that drops one die from the specified end.
    /// Use the two-argument form to drop more than one.
    /// - Parameter kind: Whether to drop the lowest or highest result.
    /// - Returns: A `SelectingDice` that drops one die from the specified end.
    public func dropping(_ kind: SelectingDice.Selection.Kind) -> SelectingDice {
        dropping(1, kind)
    }

    /// Returns a `SelectingDice` that drops `count` dice from the specified end.
    /// - Parameters:
    ///   - count: The number of dice to drop.
    ///   - kind: Whether to drop from the lowest or highest end.
    /// - Returns: A `SelectingDice` that drops the specified count from the given end.
    public func dropping(_ count: Int, _ kind: SelectingDice.Selection.Kind) -> SelectingDice {
        SelectingDice(self, selection: .init(kind: kind, count: count))
    }

    /// Returns a `SelectingDice` that keeps one die from the specified end, dropping the rest.
    /// Use the two-argument form to keep more than one.
    /// - Parameter kind: Whether to keep the lowest or highest result.
    /// - Returns: A `SelectingDice` that keeps one die from the specified end.
    public func keeping(_ kind: SelectingDice.Selection.Kind) -> SelectingDice {
        keeping(1, kind)
    }

    /// Returns a `SelectingDice` that keeps `count` dice from the specified end, dropping the rest.
    /// - Parameters:
    ///   - count: The number of dice to keep.
    ///   - kind: Whether to keep the highest or lowest results.
    /// - Returns: A `SelectingDice` that keeps the specified count from the given end.
    public func keeping(_ count: Int, _ kind: SelectingDice.Selection.Kind) -> SelectingDice {
        let dropCount = max(0, times - count)
        let dropKind: SelectingDice.Selection.Kind = kind == .highest ? .lowest : .highest
        return SelectingDice(self, selection: .init(kind: dropKind, count: dropCount), method: .keeping)
    }
}

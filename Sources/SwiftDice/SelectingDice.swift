//
//  SelectingDice.swift
//  SwiftDice
//
//  Created by Brian Arnold on 3/22/17.
//  Copyright © 2017 Brian Arnold. All rights reserved.
//


/// A selecting dice rolls a set of dice and counts only a subset of results,
/// dropping the rest. Supports both dropping notation (`4d6-L`) and keeping
/// notation (`4d6kh3`), with `description` reflecting which method it was created for.
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

    /// Wraps a Dice with a selection describing how many dice to drop and from which end.
    public init(_ dice: Dice, selection: Selection, method: Method = .dropping) {
        self.dice = dice
        self.selection = selection
        self.method = method
    }

    /// Returns the number of dice sides.
    public var sides: Int { dice.sides }

    /// Rolls the dice, drops the specified count of lowest or highest results,
    /// and returns the sum of the remaining rolls.
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

    /// Returns the string in the notation that matches how this was created.
    /// Dropping mode: `"4d6-L"`, `"5d6-L2"`. Keeping method: `"4d6kh3"`, `"2d20kh1"`.
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
    /// Drops the lowest or highest roll. Use the two-argument form to drop more than one.
    public func dropping(_ kind: SelectingDice.Selection.Kind) -> SelectingDice {
        dropping(1, kind)
    }

    /// Drops `count` lowest or highest rolls.
    public func dropping(_ count: Int, _ kind: SelectingDice.Selection.Kind) -> SelectingDice {
        SelectingDice(self, selection: .init(kind: kind, count: count))
    }

    /// Keeps the lowest or highest roll, dropping the rest.
    /// Use the two-argument form to keep more than one.
    public func keeping(_ kind: SelectingDice.Selection.Kind) -> SelectingDice {
        keeping(1, kind)
    }

    /// Keeps `count` lowest or highest rolls, dropping the rest.
    public func keeping(_ count: Int, _ kind: SelectingDice.Selection.Kind) -> SelectingDice {
        let dropCount = max(0, times - count)
        let dropKind: SelectingDice.Selection.Kind = kind == .highest ? .lowest : .highest
        return SelectingDice(self, selection: .init(kind: dropKind, count: dropCount), method: .keeping)
    }
}

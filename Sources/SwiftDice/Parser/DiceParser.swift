//
//  DiceParser.swift
//  SwiftDice
//
//  Created by Brian Arnold on 11/23/16.
//  Copyright © 2016-2017 Brian Arnold. All rights reserved.
//

import Foundation

// MARK: - Parser State

/// The internal state of the parser when it processes tokens.
private struct DiceParserState {
    private(set) var lastNumber: Int?
    private(set) var lastDice: Rollable?
    private(set) var lastMathOperator: CompoundDice.MathOperator?
    private(set) var isParsingDie = false

    /// Parses a number, storing it as die sides or as `lastNumber`.
    ///
    /// - Throws: `DiceParseError` if consecutive numbers or invalid sides are encountered
    mutating func parse(number: Int) throws {
        if isParsingDie {
            guard lastDice == nil else {
                throw DiceParseError.consecutiveDiceExpressions
            }
            guard number > 0 else {
                throw DiceParseError.invalidDieSides(number)
            }

            let times = lastNumber ?? 1
            lastDice = Dice(sides: number, times: times)
            isParsingDie = false
            lastNumber = nil
        } else {
            guard lastNumber == nil else {
                throw DiceParseError.consecutiveNumbers
            }
            lastNumber = number
        }
    }

    /// Initiates parsing a die expression.
    ///
    /// - Throws: `DiceParseError.consecutiveDiceExpressions` if already parsing a die
    mutating func parseDie() throws {
        guard !isParsingDie else {
            throw DiceParseError.consecutiveDiceExpressions
        }
        isParsingDie = true
    }

    /// Parses a Fudge die token (F/f), which must immediately follow a die token.
    ///
    /// - Throws: `DiceParseError` if not currently parsing a die, or consecutive expressions
    mutating func parseFudge() throws {
        guard isParsingDie else {
            throw DiceParseError.invalidCharacter("F")
        }
        guard lastDice == nil else {
            throw DiceParseError.consecutiveDiceExpressions
        }
        let times = lastNumber ?? 1
        lastDice = FudgeDice(times: times)
        isParsingDie = false
        lastNumber = nil
    }

    /// Parses a dropping dice modifier.
    ///
    /// - Throws: `DiceParseError` if preconditions are not met
    mutating func parse(drop: String, count: Int) throws {
        guard let dice = lastDice as? Dice else {
            throw DiceParseError.missingSimpleDice
        }
        guard lastMathOperator == .subtract else {
            throw DiceParseError.missingMinus
        }
        guard let kind = SelectingDice.Selection.Kind(rawValue: drop) else {
            throw DiceParseError.invalidCharacter(drop)
        }

        lastDice = SelectingDice(dice, selection: .init(kind: kind, count: count))
        lastMathOperator = nil
    }

    /// Parses a keeping dice modifier (kh/kl notation), converting to the equivalent drop selection.
    ///
    /// - Throws: `DiceParseError` if preconditions are not met
    mutating func parse(keep: String, count: Int) throws {
        guard let dice = lastDice as? Dice else {
            throw DiceParseError.missingSimpleDice
        }
        guard let kind = SelectingDice.Selection.Kind(rawValue: keep) else {
            throw DiceParseError.invalidCharacter(keep)
        }
        let dropCount = max(0, dice.times - count)
        let dropKind: SelectingDice.Selection.Kind = kind == .highest ? .lowest : .highest
        lastDice = SelectingDice(dice, selection: .init(kind: dropKind, count: dropCount), method: .keeping)
    }

    /// Marks the current dice as exploding.
    ///
    /// - Throws: `DiceParseError.missingSimpleDice` if no basic dice expression precedes `!`
    mutating func parseExploding() throws {
        guard let dice = lastDice as? Dice else {
            throw DiceParseError.missingSimpleDice
        }
        lastDice = dice.exploding
    }

    /// Sets the reroll threshold on the current dice.
    ///
    /// - Throws: `DiceParseError.missingSimpleDice` if no basic dice expression precedes `r<n>`
    mutating func parseReroll(threshold: Int) throws {
        guard let dice = lastDice as? Dice else {
            throw DiceParseError.missingSimpleDice
        }
        lastDice = dice.rerolling(below: threshold)
    }

    /// Parses a math operator.
    ///
    /// - Throws: `DiceParseError.consecutiveMathOperators` if another operator is pending
    mutating func parse(math: String) throws {
        guard lastMathOperator == nil else {
            throw DiceParseError.consecutiveMathOperators
        }
        let normalized = math == "*" ? "x" : math
        guard let op = CompoundDice.MathOperator(rawValue: normalized) else {
            throw DiceParseError.invalidCharacter(math)
        }
        lastMathOperator = op
    }

    /// Returns a `Rollable` from either the last number or `lastDice`, and resets their state.
    mutating func flush() -> Rollable? {
        if let number = lastNumber {
            lastNumber = nil
            return DiceModifier(number)
        } else if let dice = lastDice {
            lastDice = nil
            return dice
        }
        return nil
    }

    /// Returns combined dice from the current parsed dice and the current parse state.
    mutating func combine(_ lhsDice: Rollable?) -> Rollable? {
        guard let lhsDice else { return flush() }
        guard let mathOperator = lastMathOperator, let rhsDice = flush() else {
            return lhsDice
        }

        lastMathOperator = nil
        return CompoundDice(lhs: lhsDice, rhs: rhsDice, mathOperator: mathOperator)
    }

    /// Checks for invalid or incomplete state at the end of parsing.
    ///
    /// - Throws: `DiceParseError` if the parser is in an incomplete state
    func validate() throws {
        if isParsingDie {
            throw DiceParseError.missingDieSides
        } else if lastMathOperator != nil {
            throw DiceParseError.missingExpression
        }
    }
}

// MARK: - Public Parser

/// Converts dice notation strings into `Rollable` instances.
///
/// Create an instance and call `parse(_:)` to convert a string expression.
/// Throws `DiceParseError` on failure, allowing callers to surface specific error information.
///
/// ```swift
/// let parser = DiceParser()
/// let roll = try parser.parse("4d6-L")
/// ```
public struct DiceParser {

    public init() { }

    /// Parses a dice notation string into a `Rollable`.
    ///
    /// Supported format: `[<times>]d<sides>[!][r<n>][<mathOperator><modifier>|-<dropping>|kh<n>|kl<n>]*`
    ///
    /// Examples:
    /// - `"d8"` → 8-sided die
    /// - `"2d12+2"` → Two 12-sided dice plus 2
    /// - `"4d6-L"` → Four 6-sided dice, drop one lowest
    /// - `"4d6-L2"` → Four 6-sided dice, drop two lowest
    /// - `"4d6kh3"` → Four 6-sided dice, keep three highest
    /// - `"2d20kl1"` → Two d20, keep one lowest (disadvantage)
    /// - `"2d6!"` → Two exploding d6 (reroll and add on a 6)
    /// - `"2d6r1"` → Two d6, reroll initial 1s once (take new result)
    /// - `"1"` → Constant modifier of 1
    /// - `"2d4+3d12-4"` → Compound expression
    /// - `"4dF"` → Four Fudge dice
    ///
    /// Supported dice sides: any positive integer; d100 may be written as d%
    ///
    /// - Parameter expression: The dice notation string to parse
    /// - Returns: A `Rollable` instance representing the expression
    /// - Throws: `DiceParseError` if the expression is invalid or empty
    public func parse(_ expression: String) throws -> Rollable {
        let tokens = try tokenize(expression)
        guard let result = try evaluate(tokens) else {
            throw DiceParseError.missingExpression
        }
        return result
    }

    private func evaluate(_ tokens: [Token]) throws -> Rollable? {
        var parsedDice: Rollable?
        var state = DiceParserState()

        for (index, token) in tokens.enumerated() {
            switch token {
            case .number(let value):
                try state.parse(number: value)

            case .die:
                try state.parseDie()

            case .fudge:
                try state.parseFudge()

            case .drop(let drop, let count):
                try state.parse(drop: drop, count: count)

            case .keep(let keep, let count):
                try state.parse(keep: keep, count: count)

            case .exploding:
                try state.parseExploding()

            case .reroll(let threshold):
                try state.parseReroll(threshold: threshold)

            case .mathOperator(let math):
                if !isNextTokenDropping(tokens, after: index) {
                    parsedDice = state.combine(parsedDice)
                }
                try state.parse(math: math)
            }
        }

        parsedDice = state.combine(parsedDice)
        try state.validate()

        return parsedDice
    }

    private func isNextTokenDropping(_ tokens: [Token], after index: Int) -> Bool {
        guard index + 1 < tokens.count else { return false }
        return tokens[index + 1].isDropping
    }

    private func tokenize(_ string: String) throws -> [Token] {
        var tokens: [Token] = []
        var numberBuffer = NumberBuffer()
        let scalars = string.unicodeScalars
        var index = scalars.startIndex

        while index < scalars.endIndex {
            let scalar = scalars[index]
            index = scalars.index(after: index)

            if CharacterSet.decimalDigits.contains(scalar) {
                numberBuffer.append(scalar)
            } else {
                if let value = numberBuffer.flush() { tokens.append(.number(value)) }
                guard !CharacterSet.whitespacesAndNewlines.contains(scalar) else { continue }

                if Token.keepCharacters.contains(scalar) {
                    tokens.append(try Token.keep(leadingScalar: scalar, in: scalars, at: &index))
                    continue
                }

                if Token.rerollCharacters.contains(scalar) {
                    tokens.append(try Token.reroll(leadingScalar: scalar, in: scalars, at: &index))
                    continue
                }

                guard let token = Token(from: scalar) else {
                    throw DiceParseError.invalidCharacter(String(scalar))
                }
                tokens.append(token)
            }
        }

        if let value = numberBuffer.flush() { tokens.append(.number(value)) }
        return Token.mergingSelectingCounts(tokens)
    }
}

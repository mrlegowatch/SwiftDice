//
//  DiceParser.swift
//  SwiftDice
//
//  Created by Brian Arnold on 11/23/16.
//  Copyright © 2016 Brian Arnold. All rights reserved.
//

import Foundation

// MARK: Token Stream

private struct TokenStream {
    private let tokens: [(Token, Int)]
    private var index = 0
    let input: String
    private let endOffset: Int

    init(_ tokens: [(Token, Int)], input: String) {
        self.tokens = tokens
        self.input = input
        self.endOffset = input.unicodeScalars.count
    }

    func peek() -> Token? { index < tokens.count ? tokens[index].0 : nil }
    func peekNext() -> Token? { index + 1 < tokens.count ? tokens[index + 1].0 : nil }

    /// The Unicode scalar offset of the current token, or end-of-input if the stream is exhausted.
    var currentOffset: Int { index < tokens.count ? tokens[index].1 : endOffset }

    /// Creates a `DiceParseFailure` positioned at the current token.
    func failure(_ error: DiceParseError) -> DiceParseFailure {
        DiceParseFailure(error: error, input: input, offset: currentOffset)
    }

    @discardableResult
    mutating func consume() -> Token? {
        guard index < tokens.count else { return nil }
        defer { index += 1 }
        return tokens[index].0
    }

    var isAtEnd: Bool { index >= tokens.count }
    var isAtStart: Bool { index == 0 }
}

// MARK: - Public Parser

/// Converts dice notation strings into `Rollable` instances.
///
/// Create an instance and call `parse(_:)` to convert a string expression.
/// Throws `DiceParseFailure` on failure, giving both the error kind and a
/// compiler-style caret diagnostic pointing to the problem position in the input.
///
/// ```swift
/// let parser = DiceParser()
/// let roll = try parser.parse("4d6-L")
/// ```
public struct DiceParser {

    public init() { }

    /// Parses a dice notation string into a `Rollable`.
    ///
    /// Supports operator precedence: `*`, `x`, `/` bind more tightly than `+`, `-`.
    /// Supports parentheses for explicit grouping: `(2d6+3)*2`.
    ///
    /// Supported format: `[<times>]d<sides>[!][r<n>][<modifier>|-<dropping>|kh<n>|kl<n>]*`
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
    /// - `"-3"` → Constant modifier of -3
    /// - `"2d4+3d12-4"` → Compound expression
    /// - `"4dF"` → Four Fudge dice
    /// - `"2d6+3*2"` → `3*2` evaluated first; result range 8–18
    /// - `"(2d6+3)*2"` → parenthesized group times 2; result range 10–30
    ///
    /// Supported dice sides: any positive integer; d100 may be written as d%
    ///
    /// - Parameter expression: The dice notation string to parse
    /// - Returns: A `Rollable` instance representing the expression
    /// - Throws: `DiceParseFailure` if the expression is invalid or empty
    public func parse(_ expression: String) throws -> Rollable {
        let tokens = try tokenize(expression)
        guard !tokens.isEmpty else {
            throw DiceParseFailure(error: .missingExpression, input: expression, offset: 0)
        }
        var stream = TokenStream(tokens, input: expression)
        let result = try parseExpression(&stream)
        guard stream.isAtEnd else {
            switch stream.peek() {
            case .drop:       throw stream.failure(.missingMinus)
            case .rightParen: throw stream.failure(.invalidCharacter(")"))
            default:          throw stream.failure(.consecutiveDiceExpressions)
            }
        }
        return result
    }

    // MARK: - Recursive Descent

    private func parseExpression(_ stream: inout TokenStream) throws -> Rollable {
        try parseAdditive(&stream)
    }

    private func parseAdditive(_ stream: inout TokenStream) throws -> Rollable {
        var lhs = try parseMultiplicative(&stream)
        while let token = stream.peek(),
              case .mathOperator(let op) = token, op == "+" || op == "-" {
            stream.consume()
            let rhs = try parseMultiplicative(&stream)
            lhs = CompoundDice(lhs: lhs, rhs: rhs, mathOperator: op == "-" ? .subtract : .add)
        }
        return lhs
    }

    private func parseMultiplicative(_ stream: inout TokenStream) throws -> Rollable {
        var lhs = try parseUnary(&stream)
        while let token = stream.peek(),
              case .mathOperator(let op) = token, op == "x" || op == "*" || op == "/" {
            stream.consume()
            let rhs = try parseUnary(&stream)
            lhs = CompoundDice(lhs: lhs, rhs: rhs, mathOperator: op == "/" ? .divide : .multiply)
        }
        return lhs
    }

    // Handles leading '-' as a sign for bare numbers only, supporting round-trips
    // of DiceModifier(-n).description (e.g. "-3" → DiceModifier(-3)).
    // Only fires at the start of the full expression; "3+-4" is rejected as consecutive operators.
    private func parseUnary(_ stream: inout TokenStream) throws -> Rollable {
        if stream.isAtStart, case .mathOperator("-")? = stream.peek() {
            stream.consume()
            let operand = try parsePrimary(&stream)
            guard let modifier = operand as? DiceModifier else {
                throw stream.failure(.invalidCharacter("-"))
            }
            return DiceModifier(-modifier.modifier)
        }
        return try parsePrimary(&stream)
    }

    private func parsePrimary(_ stream: inout TokenStream) throws -> Rollable {
        if case .leftParen? = stream.peek() {
            stream.consume()
            let inner = try parseExpression(&stream)
            guard case .rightParen? = stream.peek() else {
                throw stream.failure(.missingClosingParen)
            }
            stream.consume()
            return inner
        }

        var times = 1
        if case .number(let n)? = stream.peek(), case .die? = stream.peekNext() {
            stream.consume()
            times = n
        }

        if case .die? = stream.peek() {
            stream.consume()
            return try parseDiceExpr(&stream, times: times)
        }

        if case .number(let n)? = stream.peek() {
            stream.consume()
            return DiceModifier(n)
        }

        if case .fudge? = stream.peek() {
            throw stream.failure(.invalidCharacter("F"))
        }

        if case .exploding? = stream.peek() {
            throw stream.failure(.missingSimpleDice)
        }

        throw stream.failure(.missingExpression)
    }

    private func parseDiceExpr(_ stream: inout TokenStream, times: Int) throws -> Rollable {
        switch stream.peek() {
        case .number(let sides):
            guard sides > 0 else { throw stream.failure(.invalidDieSides(sides)) }
            stream.consume()
            return try parseDiceModifiers(&stream, dice: Dice(sides: sides, times: times))
        case .fudge:
            stream.consume()
            try rejectFudgeModifiers(&stream)
            return FudgeDice(times: times)
        default:
            throw stream.failure(.missingDieSides)
        }
    }

    private func parseDiceModifiers(_ stream: inout TokenStream, dice: Dice) throws -> Rollable {
        var currentDice = dice

        modifiers: while true {
            switch stream.peek() {
            case .exploding:
                stream.consume()
                currentDice = currentDice.exploding
            case .reroll(let threshold):
                stream.consume()
                currentDice = currentDice.rerolling(below: threshold)
            default:
                break modifiers
            }
        }

        switch stream.peek() {
        case .keep(let kindStr, let count):
            stream.consume()
            guard let kind = SelectingDice.Selection.Kind(rawValue: kindStr) else {
                throw stream.failure(.invalidCharacter(kindStr))
            }
            let dropCount = max(0, currentDice.times - count)
            let dropKind: SelectingDice.Selection.Kind = kind == .highest ? .lowest : .highest
            return SelectingDice(currentDice, selection: .init(kind: dropKind, count: dropCount), method: .keeping)
        case .mathOperator("-"):
            guard case .drop(let char, let count)? = stream.peekNext() else { return currentDice }
            stream.consume()
            stream.consume()
            guard let kind = SelectingDice.Selection.Kind(rawValue: char) else {
                throw stream.failure(.invalidCharacter(char))
            }
            return SelectingDice(currentDice, selection: .init(kind: kind, count: count))
        default:
            return currentDice
        }
    }

    // Fudge dice do not support any postfix modifiers; throws if one is present.
    private func rejectFudgeModifiers(_ stream: inout TokenStream) throws {
        switch stream.peek() {
        case .exploding, .reroll, .keep:
            throw stream.failure(.missingSimpleDice)
        case .mathOperator("-"):
            if case .drop? = stream.peekNext() {
                throw stream.failure(.missingSimpleDice)
            }
        default:
            break
        }
    }

    // MARK: - Tokenizer

    private func tokenize(_ string: String) throws -> [(Token, Int)] {
        var tokens: [(Token, Int)] = []
        var numberBuffer = NumberBuffer()
        let scalars = string.unicodeScalars
        var index = scalars.startIndex

        while index < scalars.endIndex {
            let scalar = scalars[index]
            let offset = scalars.distance(from: scalars.startIndex, to: index)
            index = scalars.index(after: index)

            if CharacterSet.decimalDigits.contains(scalar) {
                numberBuffer.append(scalar, at: offset)
            } else {
                if let (value, numOffset) = numberBuffer.flush() {
                    tokens.append((.number(value), numOffset))
                }
                guard !CharacterSet.whitespacesAndNewlines.contains(scalar) else { continue }

                if Token.keepCharacters.contains(scalar) {
                    do {
                        let tok = try Token.keep(leadingScalar: scalar, in: scalars, at: &index)
                        tokens.append((tok, offset))
                    } catch let e as DiceParseError {
                        throw DiceParseFailure(error: e, input: string, offset: offset)
                    }
                    continue
                }

                if Token.rerollCharacters.contains(scalar) {
                    do {
                        let tok = try Token.reroll(leadingScalar: scalar, in: scalars, at: &index)
                        tokens.append((tok, offset))
                    } catch let e as DiceParseError {
                        throw DiceParseFailure(error: e, input: string, offset: offset)
                    }
                    continue
                }

                guard let token = Token(from: scalar) else {
                    throw DiceParseFailure(error: .invalidCharacter(String(scalar)), input: string, offset: offset)
                }
                tokens.append((token, offset))
            }
        }

        if let (value, numOffset) = numberBuffer.flush() {
            tokens.append((.number(value), numOffset))
        }
        return Token.mergingSelectingCounts(tokens)
    }
}

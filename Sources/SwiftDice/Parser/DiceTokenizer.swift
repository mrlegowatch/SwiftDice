//
//  DiceTokenizer.swift
//  SwiftDice
//
//  Created by Brian Arnold on 11/23/16.
//  Copyright © 2016 Brian Arnold. All rights reserved.
//

import Foundation

// MARK: - Parse Errors

/// Types of errors handled by this parser.
public enum DiceParseError: Error, LocalizedError, Sendable {
    case invalidCharacter(String)
    case invalidDieSides(Int)
    case missingMinus
    case missingSimpleDice
    case missingDieSides
    case missingExpression
    case consecutiveNumbers
    case consecutiveMathOperators
    case consecutiveDiceExpressions

    public var errorDescription: String? {
        switch self {
        case .invalidCharacter(let char):
            return "Invalid character '\(char)' in dice expression"
        case .invalidDieSides(let sides):
            return "Invalid die with \(sides) sides"
        case .missingMinus:
            return "Drop modifier requires '-' operator"
        case .missingSimpleDice:
            return "Drop modifier can only be applied to a basic dice expression"
        case .missingDieSides:
            return "Die specification missing number of sides"
        case .missingExpression:
            return "Math operator missing right-hand expression"
        case .consecutiveNumbers:
            return "Cannot have consecutive numbers without an operator"
        case .consecutiveMathOperators:
            return "Cannot have consecutive math operators"
        case .consecutiveDiceExpressions:
            return "Cannot have consecutive dice expressions without an operator"
        }
    }
}

// MARK: - Token

/// Types of tokens produced by the tokenizer.
enum Token {
    case number(Int)
    case mathOperator(String)
    case die
    case drop(String, Int)
    case keep(String, Int)
    case fudge
    case exploding
    case reroll(Int)

    // MARK: Single-character recognition

    /// Each entry pairs a character set with a factory producing the corresponding token.
    /// Add a new entry here to support an additional single-character token.
    private static let recognizers: [(CharacterSet, @Sendable (UnicodeScalar) -> Token?)] = [
        (CharacterSet(charactersIn: "+-x*/"), { .mathOperator(String($0)) }),
        (CharacterSet(charactersIn: "dD"),    { _ in .die }),
        (CharacterSet(charactersIn: "LH"),    { .drop(String($0), 1) }),
        (CharacterSet(charactersIn: "%"),     { _ in .number(100) }),
        (CharacterSet(charactersIn: "fF"),    { _ in .fudge }),
        (CharacterSet(charactersIn: "!"),     { _ in .exploding }),
    ]
    static let keepCharacters = CharacterSet(charactersIn: "kK")
    static let rerollCharacters = CharacterSet(charactersIn: "rR")

    /// Initializes a token from a single Unicode scalar. Returns `nil` for characters
    /// that require multi-character lookahead (`k`/`K` for keep, `r`/`R` for reroll),
    /// which are handled inline in `tokenize(_:)`.
    init?(from scalar: UnicodeScalar) {
        for (characterSet, factory) in Self.recognizers where characterSet.contains(scalar) {
            if let token = factory(scalar) {
                self = token
                return
            }
        }
        return nil
    }

    // MARK: Multi-character token factories

    /// Reads the keep-direction character following a `k`/`K` scalar, advancing `index` past it.
    static func keep(leadingScalar: UnicodeScalar, in scalars: String.UnicodeScalarView, at index: inout String.UnicodeScalarView.Index) throws -> Token {
        guard index < scalars.endIndex,
              let kind = SelectingDice.Selection.Kind(rawValue: String(scalars[index]).uppercased()) else {
            throw DiceParseError.invalidCharacter(String(leadingScalar))
        }
        index = scalars.index(after: index)
        return .keep(kind.rawValue, 1)
    }

    /// Reads the numeric threshold following an `r`/`R` scalar, advancing `index` past the digits.
    static func reroll(leadingScalar: UnicodeScalar, in scalars: String.UnicodeScalarView, at index: inout String.UnicodeScalarView.Index) throws -> Token {
        var thresholdStr = ""
        while index < scalars.endIndex && CharacterSet.decimalDigits.contains(scalars[index]) {
            thresholdStr.append(String(scalars[index]))
            index = scalars.index(after: index)
        }
        guard !thresholdStr.isEmpty, let threshold = Int(thresholdStr) else {
            throw DiceParseError.invalidCharacter(String(leadingScalar))
        }
        return .reroll(threshold)
    }

    // MARK: Token array operations

    /// Merges `.drop`/`.keep` tokens immediately followed by `.number(n)` into a single token,
    /// supporting notation like `"4d6-L2"` and `"4d6kh3"`.
    static func mergingSelectingCounts(_ tokens: [Token]) -> [Token] {
        var result: [Token] = []
        var i = 0
        while i < tokens.count {
            if case .drop(let char, _) = tokens[i],
               i + 1 < tokens.count,
               case .number(let count) = tokens[i + 1] {
                result.append(.drop(char, count))
                i += 2
            } else if case .keep(let char, _) = tokens[i],
                      i + 1 < tokens.count,
                      case .number(let count) = tokens[i + 1] {
                result.append(.keep(char, count))
                i += 2
            } else {
                result.append(tokens[i])
                i += 1
            }
        }
        return result
    }

    // MARK: Properties

    var isDropping: Bool {
        if case .drop = self { return true }
        return false
    }
}

// MARK: - Number Buffer

struct NumberBuffer {
    private var buffer = ""

    mutating func append(_ scalar: UnicodeScalar) {
        buffer.append(String(scalar))
    }

    mutating func flush() -> Int? {
        guard !buffer.isEmpty else { return nil }
        defer { buffer = "" }
        return Int(buffer)
    }
}


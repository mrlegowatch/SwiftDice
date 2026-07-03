//
//  DiceTokenizer.swift
//  SwiftDice
//
//  Created by Brian Arnold on 11/23/16.
//  Copyright © 2016-2017 Brian Arnold. All rights reserved.
//

import Foundation

// MARK: - Parse Errors

/// Types of errors handled by this parser.
enum DiceParseError: Error, LocalizedError, Sendable {
    case invalidCharacter(String)
    case invalidDieSides(Int)
    case missingMinus
    case missingSimpleDice
    case missingDieSides
    case missingExpression
    case consecutiveNumbers
    case consecutiveMathOperators
    case consecutiveDiceExpressions

    var errorDescription: String? {
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

    // MARK: Properties

    var isDropping: Bool {
        if case .drop = self { return true }
        return false
    }
}

// MARK: - Number Buffer

private struct NumberBuffer {
    private var buffer = ""

    var isEmpty: Bool { buffer.isEmpty }

    mutating func append(_ scalar: UnicodeScalar) {
        buffer.append(String(scalar))
    }

    mutating func flush() -> Int? {
        guard !buffer.isEmpty else { return nil }
        defer { buffer = "" }
        return Int(buffer)
    }
}

// MARK: - Tokenizer

/// Converts a dice-formatted string into a sequence of tokens.
///
/// - Parameter string: The string to tokenize (e.g., "2d6+3", "4dF")
/// - Returns: An array of tokens representing the parsed string
/// - Throws: `DiceParseError.invalidCharacter` if an unknown character is encountered
func tokenize(_ string: String) throws -> [Token] {
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
                guard index < scalars.endIndex,
                      let kind = SelectingDice.Selection.Kind(rawValue: String(scalars[index]).uppercased()) else {
                    throw DiceParseError.invalidCharacter(String(scalar))
                }
                tokens.append(.keep(kind.rawValue, 1))
                index = scalars.index(after: index)
                continue
            }

            if Token.rerollCharacters.contains(scalar) {
                var thresholdStr = ""
                while index < scalars.endIndex && CharacterSet.decimalDigits.contains(scalars[index]) {
                    thresholdStr.append(String(scalars[index]))
                    index = scalars.index(after: index)
                }
                guard !thresholdStr.isEmpty, let threshold = Int(thresholdStr) else {
                    throw DiceParseError.invalidCharacter(String(scalar))
                }
                tokens.append(.reroll(threshold))
                continue
            }

            guard let token = Token(from: scalar) else {
                throw DiceParseError.invalidCharacter(String(scalar))
            }
            tokens.append(token)
        }
    }

    if let value = numberBuffer.flush() { tokens.append(.number(value)) }
    return mergeSelectingCount(tokens)
}

/// Merges `.drop`/`.keep` tokens immediately followed by `.number(n)` into a single token,
/// supporting notation like `"4d6-L2"` and `"4d6kh3"`.
private func mergeSelectingCount(_ tokens: [Token]) -> [Token] {
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

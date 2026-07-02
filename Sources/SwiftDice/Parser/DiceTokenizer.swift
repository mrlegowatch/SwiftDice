//
//  DiceTokenizer.swift
//  SwiftDice
//
//  Created by Brian Arnold on 11/23/16.
//  Copyright © 2016 Brian Arnold. All rights reserved.
//

import Foundation


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
    case leftParen
    case rightParen

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
        (CharacterSet(charactersIn: "("),     { _ in .leftParen }),
        (CharacterSet(charactersIn: ")"),     { _ in .rightParen }),
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
    /// supporting notation like `"4d6-L2"` and `"4d6kh3"`. Preserves the source offset of
    /// the first token in each merged pair.
    static func mergingSelectingCounts(_ tokens: [(Token, Int)]) -> [(Token, Int)] {
        var result: [(Token, Int)] = []
        var i = 0
        while i < tokens.count {
            if case .drop(let char, _) = tokens[i].0,
               i + 1 < tokens.count,
               case .number(let count) = tokens[i + 1].0 {
                result.append((.drop(char, count), tokens[i].1))
                i += 2
            } else if case .keep(let char, _) = tokens[i].0,
                      i + 1 < tokens.count,
                      case .number(let count) = tokens[i + 1].0 {
                result.append((.keep(char, count), tokens[i].1))
                i += 2
            } else {
                result.append(tokens[i])
                i += 1
            }
        }
        return result
    }

}

// MARK: - Number Buffer

struct NumberBuffer {
    private var buffer = ""
    private var startOffset = 0

    mutating func append(_ scalar: UnicodeScalar, at offset: Int) {
        if buffer.isEmpty { startOffset = offset }
        buffer.append(String(scalar))
    }

    mutating func flush() -> (value: Int, startOffset: Int)? {
        guard !buffer.isEmpty, let value = Int(buffer) else {
            buffer = ""
            return nil
        }
        defer { buffer = "" }
        return (value, startOffset)
    }
}

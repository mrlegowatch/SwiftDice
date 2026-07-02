//
//  DiceParseFailure.swift
//  SwiftDice
//
//  Created by Brian Arnold on 11/23/16.
//  Copyright © 2016 Brian Arnold. All rights reserved.
//

import Foundation

// MARK: Parse Errors

/// Types of errors handled by this parser.
public enum DiceParseError: Error, LocalizedError, Equatable, Sendable {
    case invalidCharacter(String)
    case invalidDieSides(Int)
    case missingMinus
    case missingSimpleDice
    case missingDieSides
    case missingExpression
    case consecutiveDiceExpressions
    case missingClosingParen

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
        case .consecutiveDiceExpressions:
            return "Cannot have consecutive dice expressions without an operator"
        case .missingClosingParen:
            return "Missing closing parenthesis in dice expression"
        }
    }
}

// MARK: - Parse Failure

/// A parse error paired with source context for compiler-style diagnostic display.
///
/// Thrown by `DiceParser.parse(_:)`. Use `error` to programmatically inspect the
/// failure kind; use `localizedDescription` (or `errorDescription`) for a human-readable
/// diagnostic with a caret indicating the position of the problem:
///
/// ```
/// Invalid character 'H' in dice expression
/// 2d4H
///    ^
/// ```
public struct DiceParseFailure: Error, LocalizedError, Sendable {
    /// The specific parse error that occurred.
    public let error: DiceParseError
    /// The original expression that failed to parse.
    public let input: String
    /// The Unicode scalar offset within `input` where the error was detected.
    public let offset: Int

    public var errorDescription: String? {
        let base = error.errorDescription ?? "Unknown error"
        let safeOffset = min(offset, input.unicodeScalars.count)
        let caret = String(repeating: " ", count: safeOffset) + "^"
        return "\(base)\n\(input)\n\(caret)"
    }
}

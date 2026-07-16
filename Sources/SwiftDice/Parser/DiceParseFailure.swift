//
//  DiceParseFailure.swift
//  SwiftDice
//
//  Created by Brian Arnold on 11/23/16.
//  Copyright © 2016 Brian Arnold. All rights reserved.
//

import Foundation

// MARK: Parse Errors

/// The specific kind of error that caused a dice notation string to fail parsing.
///
/// Returned as `DiceParseFailure.error` after catching a parse failure from `DiceParser.parse(_:)`.
/// Use the cases to branch on the failure kind programmatically; use `errorDescription` for a
/// human-readable message suitable for display.
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
            return "Die sides must be a positive integer (got \(sides)); try 'd6', 'd20', or any positive number"
        case .missingMinus:
            return "Drop notation requires a preceding '-' (e.g. \"4d6-L\", not \"4d6L\")"
        case .missingSimpleDice:
            return "This modifier requires a preceding basic dice expression (e.g. '2d6'); Fudge dice and bare operators are not supported here"
        case .missingDieSides:
            return "Expected a number, 'F', or '%' after 'd' (e.g. 'd6', 'd20', 'd%', 'dF')"
        case .missingExpression:
            return "Expected a dice expression (e.g. 'd6', '2d8+4'); the input is empty or ends with an incomplete operator"
        case .consecutiveDiceExpressions:
            return "Unexpected token after a complete expression; did you forget an operator? (e.g. 'd4+d4', '2+3')"
        case .missingClosingParen:
            return "Unmatched '(' — add a closing ')' to complete the group"
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

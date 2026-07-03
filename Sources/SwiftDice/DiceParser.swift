//
//  DiceParser.swift
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

/// Types of tokens supported by this parser.
enum Token {
    case number(Int)
    case mathOperator(String)
    case die
    case drop(String, Int)
    case keep(String, Int)
    case fudge
    case exploding
    case reroll(Int)

    // MARK: Character Sets

    private static let mathOperatorCharacters = CharacterSet(charactersIn: "+-x*/")
    private static let dieCharacters = CharacterSet(charactersIn: "dD")
    private static let dropCharacters = CharacterSet(
        charactersIn: SelectingDice.Selection.Kind.allCases.map(\.rawValue).joined()
    )
    private static let percentCharacters = CharacterSet(charactersIn: "%")
    private static let fudgeCharacters = CharacterSet(charactersIn: "fF")
    private static let explodingCharacters = CharacterSet(charactersIn: "!")

    // MARK: Initialization

    init?(from scalar: UnicodeScalar) {
        switch scalar {
        case _ where Self.mathOperatorCharacters.contains(scalar):
            self = .mathOperator(String(scalar))
        case _ where Self.dieCharacters.contains(scalar):
            self = .die
        case _ where Self.dropCharacters.contains(scalar):
            self = .drop(String(scalar), 1)
        case _ where Self.percentCharacters.contains(scalar):
            self = .number(100)
        case _ where Self.fudgeCharacters.contains(scalar):
            self = .fudge
        case _ where Self.explodingCharacters.contains(scalar):
            self = .exploding
        default:
            return nil
        }
    }

    // MARK: Properties

    var isDropping: Bool {
        if case .drop = self { return true }
        return false
    }

    var isKeeping: Bool {
        if case .keep = self { return true }
        return false
    }
}

// MARK: - Number Buffer

/// An internal buffer for parsing numbers from a string.
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
    let keepCharacters = CharacterSet(charactersIn: "kK")
    let rerollCharacters = CharacterSet(charactersIn: "rR")
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

            if keepCharacters.contains(scalar) {
                guard index < scalars.endIndex,
                      let kind = SelectingDice.Selection.Kind(rawValue: String(scalars[index]).uppercased()) else {
                    throw DiceParseError.invalidCharacter(String(scalar))
                }
                tokens.append(.keep(kind.rawValue, 1))
                index = scalars.index(after: index)
                continue
            }

            if rerollCharacters.contains(scalar) {
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

// MARK: - Parser State

/// The internal state of the parser when it processes tokens.
private struct DiceParserState {
    private(set) var lastNumber: Int?
    private(set) var lastDice: Rollable?
    private(set) var lastMathOperator: CompoundDice.MathOperator?
    private(set) var isParsingDie = false

    // MARK: Parsing Methods

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

// MARK: - Parser

/// Look-ahead at the next token and return whether it's a `.drop` token.
private func isNextTokenDropping(_ tokens: [Token], after index: Int) -> Bool {
    guard index + 1 < tokens.count else { return false }
    return tokens[index + 1].isDropping
}

/// Converts an array of tokens into a `Rollable` object.
///
/// - Parameter tokens: The tokens to parse
/// - Returns: A `Rollable` instance representing the parsed expression, or `nil` if empty
/// - Throws: `DiceParseError` if the token sequence is invalid
func parse(_ tokens: [Token]) throws -> Rollable? {
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

// MARK: - String Extension

public extension String {

    /// Creates a `Rollable` instance from a dice notation string.
    ///
    /// Supported format: `[<times>]d<sides>[<mathOperator><modifier>|-<dropping>|kh<n>|kl<n>]*`
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
    /// - Returns: A `Rollable` instance, or `nil` if the string cannot be parsed
    var parseDice: Rollable? {
        do {
            let tokens = try tokenize(self)
            return try parse(tokens)
        } catch {
            print("Error parsing dice: \(error.localizedDescription)")
            return nil
        }
    }
}

// MARK: - Decoding Extensions

public extension KeyedDecodingContainer {

    /// Decodes either an integer or a dice notation string into a `Rollable`.
    ///
    /// - Parameters:
    ///   - type: The `Rollable.Protocol` metatype
    ///   - key: The coding key for the value
    /// - Returns: A decoded `Rollable` instance
    /// - Throws: `DecodingError.dataCorrupted` if the value cannot be decoded as dice
    func decode(_ type: Rollable.Protocol, forKey key: K) throws -> Rollable {
        if let number = try? decode(Int.self, forKey: key) {
            return DiceModifier(number)
        }

        if let string = try? decode(String.self, forKey: key),
           let dice = string.parseDice {
            return dice
        }

        let context = DecodingError.Context(
            codingPath: codingPath,
            debugDescription: "Could not decode Rollable from string or number"
        )
        throw DecodingError.dataCorrupted(context)
    }

    /// Decodes either an integer or a dice notation string into a `Rollable`, if present.
    ///
    /// - Parameters:
    ///   - type: The `Rollable.Protocol` metatype
    ///   - key: The coding key for the value
    /// - Returns: A decoded `Rollable` instance, or `nil` if the key is not present
    /// - Throws: `DecodingError.dataCorrupted` if the value is present but cannot be decoded
    func decodeIfPresent(_ type: Rollable.Protocol, forKey key: K) throws -> Rollable? {
        guard contains(key) else { return nil }

        if let number = try? decode(Int.self, forKey: key) {
            return DiceModifier(number)
        }

        if let string = try? decode(String.self, forKey: key) {
            return string.parseDice
        }

        return nil
    }
}

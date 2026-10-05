//
//  AnyRollable.swift
//  SwiftDice
//
//  Created by Brian Arnold on 10/5/26.
//  Copyright © 2026 Brian Arnold. All rights reserved.
//

/// A type-erased `Rollable`, for storage, comparison and coding.
///
/// `Rollable` is a protocol, so a bare `any Rollable` cannot be compared, hashed, or
/// encoded without extra plumbing. `AnyRollable` wraps any `Rollable` so it can be
/// stored in a struct and get `Equatable`, `Hashable`, and `Codable` for free:
///
/// ```swift
/// struct Treasure: Codable {
///     let goldPerGoblin: AnyRollable   // "d6", "2d6", or a plain constant
/// }
/// ```
///
/// Two expressions are equal and hash alike when they print the same notation:
///
/// ```swift
/// AnyRollable(parsing: "1d6") == AnyRollable(Dice.d6)  // true, both print "d6"
/// ```
///
/// Integer literals construct a constant expression directly:
///
/// ```swift
/// let flat: AnyRollable = 3
/// flat.constant  // 3
/// ```
public struct AnyRollable: Rollable, Hashable, Codable, ExpressibleByIntegerLiteral {

    /// The wrapped expression.
    public let rollable: any Rollable

    /// Wraps a `Rollable` expression. If `rollable` is already an `AnyRollable`, its
    /// underlying expression is unwrapped rather than nested.
    /// - Parameter rollable: The expression to wrap.
    public init(_ rollable: any Rollable) {
        if let expression = rollable as? AnyRollable {
            self.rollable = expression.rollable
        } else {
            self.rollable = rollable
        }
    }

    /// Wraps a constant integer value as a `DiceModifier`.
    /// - Parameter constant: The fixed value returned by every `roll()`.
    public init(_ constant: Int) {
        self.rollable = DiceModifier(constant)
    }

    /// Creates a constant expression from an integer literal.
    public init(integerLiteral value: Int) {
        self.init(value)
    }

    /// Parses a dice notation string into an expression.
    /// - Parameter notation: The dice notation string, e.g. `"2d8+4"`.
    /// - Throws: `DiceParseFailure` if `notation` is not a valid dice expression.
    public init(parsing notation: String) throws {
        self.init(try DiceParser().parse(notation))
    }

    /// The fixed value when this expression is a plain number (a `DiceModifier`), otherwise `nil`.
    public var constant: Int? {
        (rollable as? DiceModifier)?.modifier
    }

    /// Whether this expression is a plain number (a `DiceModifier`).
    public var isConstant: Bool {
        constant != nil
    }

    /// Rolls the wrapped expression.
    /// - Returns: The `DiceRoll` produced by the wrapped expression.
    public func roll() -> DiceRoll {
        rollable.roll()
    }

    /// The dice notation of the wrapped expression.
    public var description: String {
        rollable.description
    }

    public static func ==(lhs: AnyRollable, rhs: AnyRollable) -> Bool {
        lhs.description == rhs.description
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(description)
    }

    /// Decodes either a JSON integer (as a constant) or a dice notation string.
    /// - Throws: `DecodingError.dataCorrupted` if the value is neither an `Int` nor a
    ///   parseable dice notation `String`.
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let constant = try? container.decode(Int.self) {
            self.init(constant)
            return
        }

        guard let notation = try? container.decode(String.self) else {
            let context = DecodingError.Context(
                codingPath: container.codingPath,
                debugDescription: "Could not decode AnyRollable: expected an Int or a dice notation String"
            )
            throw DecodingError.dataCorrupted(context)
        }

        do {
            self.init(try DiceParser().parse(notation))
        } catch let failure as DiceParseFailure {
            let context = DecodingError.Context(
                codingPath: container.codingPath,
                debugDescription: "Could not decode AnyRollable from '\(notation)': \(failure.errorDescription ?? "unknown parse error")"
            )
            throw DecodingError.dataCorrupted(context)
        }
    }

    /// Encodes a constant as a JSON integer; any other expression encodes as its notation string.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let constant {
            try container.encode(constant)
        } else {
            try container.encode(description)
        }
    }
}

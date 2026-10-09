//
//  AnyRollableTests.swift
//  SwiftDiceTests
//
//  Created by Brian Arnold on 10/5/26.
//  Copyright © 2026 Brian Arnold. Licensed under the MIT License.
//

import Testing
import SwiftDice
import Foundation

@Suite("AnyRollable Tests")
struct AnyRollableTests {

    private struct Container: Codable {
        let n: AnyRollable
    }

    private struct OptionalContainer: Codable {
        let n: AnyRollable?
    }

    // MARK: - Constant

    @Test("Constant from init(_:)")
    func constantFromInit() {
        let expression = AnyRollable(3)
        #expect(expression.constant == 3)
        #expect(expression.isConstant)
    }

    @Test("Constant from integer literal")
    func constantFromLiteral() {
        let expression: AnyRollable = 3
        #expect(expression.constant == 3)
        #expect(expression.isConstant)
    }

    @Test("Constant from parsing")
    func constantFromParsing() throws {
        let expression = try AnyRollable(parsing: "3")
        #expect(expression.constant == 3)
        #expect(expression.isConstant)
    }

    @Test("Non-constant has nil constant and false isConstant")
    func nonConstant() throws {
        let expression = try AnyRollable(parsing: "2d6")
        #expect(expression.constant == nil)
        #expect(!expression.isConstant)
    }

    // MARK: - Equality and hashing

    @Test("1d6 equals Dice.d6")
    func equalityAcrossNotation() throws {
        let parsed = try AnyRollable(parsing: "1d6")
        let fromDice = AnyRollable(Dice.d6)
        #expect(parsed == fromDice)
    }

    @Test("2d6 does not equal d6")
    func inequality() throws {
        let twoD6 = try AnyRollable(parsing: "2d6")
        let oneD6 = try AnyRollable(parsing: "d6")
        #expect(twoD6 != oneD6)
    }

    @Test("Set of equal-notation expressions dedupes")
    func setDeduplication() throws {
        let expressions: Set<AnyRollable> = [
            try AnyRollable(parsing: "d6"),
            try AnyRollable(parsing: "1d6"),
            try AnyRollable(parsing: "2d8+4"),
        ]
        #expect(expressions.count == 2)
    }

    // MARK: - Decoding

    @Test("Decode constant from JSON integer")
    func decodeConstant() throws {
        let json = #"{"n": 8}"#.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(Container.self, from: json)
        #expect(decoded.n.constant == 8)
    }

    @Test("Decode compound expression from JSON string")
    func decodeCompound() throws {
        let json = #"{"n": "4d2+4"}"#.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(Container.self, from: json)
        #expect(decoded.n.description == "4d2+4")
        #expect(decoded.n.rollable is CompoundDice)
    }

    @Test("Decode simple die equals Dice.d6")
    func decodeSimpleDie() throws {
        let json = #"{"n": "d6"}"#.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(Container.self, from: json)
        #expect(decoded.n == AnyRollable(Dice.d6))
        #expect(decoded.n.rollable is Dice)
    }

    @Test("Decode failure - unparseable string")
    func decodeFailureUnparseableString() {
        let json = #"{"n": "banana"}"#.data(using: .utf8)!
        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder().decode(Container.self, from: json)
        }
    }

    @Test("Decode failure - boolean")
    func decodeFailureBoolean() {
        let json = #"{"n": true}"#.data(using: .utf8)!
        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder().decode(Container.self, from: json)
        }
    }

    @Test("Decode failure - floating point")
    func decodeFailureFloatingPoint() {
        let json = #"{"n": 1.5}"#.data(using: .utf8)!
        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder().decode(Container.self, from: json)
        }
    }

    // MARK: - Optional coding

    @Test("Decode optional - present as integer")
    func decodeOptionalPresentInteger() throws {
        let json = #"{"n": 5}"#.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(OptionalContainer.self, from: json)
        #expect(decoded.n?.constant == 5)
    }

    @Test("Decode optional - present as string")
    func decodeOptionalPresentString() throws {
        let json = #"{"n": "2d6+2"}"#.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(OptionalContainer.self, from: json)
        #expect(decoded.n?.rollable is CompoundDice)
    }

    @Test("Decode optional - absent")
    func decodeOptionalAbsent() throws {
        let json = #"{}"#.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(OptionalContainer.self, from: json)
        #expect(decoded.n == nil)
    }

    @Test("Decode optional - present but unparseable throws")
    func decodeOptionalPresentUnparseableThrows() {
        let json = #"{"n": "Hello Dice"}"#.data(using: .utf8)!
        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder().decode(OptionalContainer.self, from: json)
        }
    }

    @Test("Encode optional - present")
    func encodeOptionalPresent() throws {
        let encoded = try JSONEncoder().encode(OptionalContainer(n: AnyRollable(Dice.d6)))
        let deserialized = try JSONSerialization.jsonObject(with: encoded) as? [String: String]
        #expect(deserialized?["n"] == "d6")
    }

    @Test("Encode optional - nil omits key")
    func encodeOptionalNil() throws {
        let encoded = try JSONEncoder().encode(OptionalContainer(n: nil))
        let deserialized = try JSONSerialization.jsonObject(with: encoded) as? [String: String]
        #expect(deserialized?["n"] == nil)
    }

    // MARK: - Encoding

    @Test("Encode round trip - constant")
    func encodeRoundTripConstant() throws {
        let container = Container(n: AnyRollable(8))
        let encoded = try JSONEncoder().encode(container)
        let deserialized = try JSONSerialization.jsonObject(with: encoded) as? [String: Int]
        #expect(deserialized?["n"] == 8)

        let decoded = try JSONDecoder().decode(Container.self, from: encoded)
        #expect(decoded.n == container.n)
    }

    @Test("Encode round trip - compound expression")
    func encodeRoundTripCompound() throws {
        let container = Container(n: try AnyRollable(parsing: "2d8+4"))
        let encoded = try JSONEncoder().encode(container)
        let deserialized = try JSONSerialization.jsonObject(with: encoded) as? [String: String]
        #expect(deserialized?["n"] == "2d8+4")

        let decoded = try JSONDecoder().decode(Container.self, from: encoded)
        #expect(decoded.n == container.n)
    }

    @Test("Encode round trip - simple die")
    func encodeRoundTripSimpleDie() throws {
        let container = Container(n: AnyRollable(Dice.d8))
        let encoded = try JSONEncoder().encode(container)
        let decoded = try JSONDecoder().decode(Container.self, from: encoded)
        #expect(decoded.n == container.n)
    }

    @Test("Encode round trip - selecting dice")
    func encodeRoundTripSelectingDice() throws {
        let container = Container(n: AnyRollable((4 * Dice.d6).dropping(.lowest)))
        let encoded = try JSONEncoder().encode(container)
        let decoded = try JSONDecoder().decode(Container.self, from: encoded)
        #expect(decoded.n == container.n)
    }

    @Test("Encode round trip - Fudge dice")
    func encodeRoundTripFudgeDice() throws {
        let container = Container(n: AnyRollable(4 * FudgeDice.dF))
        let encoded = try JSONEncoder().encode(container)
        let decoded = try JSONDecoder().decode(Container.self, from: encoded)
        #expect(decoded.n == container.n)
    }

    // MARK: - Rolling

    @Test("roll() for d4+1 stays in 2...5")
    func rollRange() throws {
        let expression = try AnyRollable(parsing: "d4+1")
        rollSample(expression, in: 2...5)
    }

    // MARK: - Unwrapping

    @Test("Wrapping an AnyRollable unwraps rather than nesting")
    func unwrapsNestedExpression() {
        let expression = AnyRollable(AnyRollable(Dice.d6))
        #expect(expression.rollable is Dice)
    }

    // MARK: - Array decoding

    @Test("Array of AnyRollable decodes from notation strings")
    func decodeArray() throws {
        let json = #"["d2", "d2", "d4+1"]"#.data(using: .utf8)!
        let decoded = try JSONDecoder().decode([AnyRollable].self, from: json)
        #expect(decoded.count == 3)
        #expect(decoded[0] == decoded[1])
        #expect(decoded[2].description == "d4+1")
    }
}

//
//  DiceCodingTests.swift
//  SwiftDice
//
//  Created by Brian Arnold on 10/29/25.
//  Copyright © 2025 Brian Arnold. All rights reserved.
//

import Testing
import SwiftDice
import Foundation

@Suite("Dice encoding and decoding Tests")
struct DiceCodingTests {

    private struct EncodableDiceContainer: Encodable {
        let dice: Rollable
        enum CodingKeys: String, CodingKey { case dice }
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(dice, forKey: .dice)
        }
    }

    private struct EncodableOptionalDiceContainer: Encodable {
        let dice: Rollable?
        enum CodingKeys: String, CodingKey { case dice }
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encodeIfPresent(dice, forKey: .dice)
        }
    }

    private struct DecodableDiceContainer: Decodable {
        let dice: Rollable
        enum CodingKeys: String, CodingKey { case dice }
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            dice = try container.decode(Rollable.self, forKey: .dice)
        }
    }

    private struct OptionalDiceContainer: Decodable {
        let dice: Rollable?
        enum CodingKeys: String, CodingKey { case dice }
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            dice = try container.decodeIfPresent(Rollable.self, forKey: .dice)
        }
    }

    @Test("Encoding dice")
    func encodingDice() throws {
        let encoded = try JSONEncoder().encode(EncodableDiceContainer(dice: 3 * Dice.d8 - 3))
        let deserialized = try JSONSerialization.jsonObject(with: encoded) as? [String: String]
        #expect(deserialized?["dice"] == "3d8-3")
    }

    @Test("Encoding optional dice - present")
    func encodingOptionalDicePresent() throws {
        let encoded = try JSONEncoder().encode(EncodableOptionalDiceContainer(dice: Dice.d6))
        let deserialized = try JSONSerialization.jsonObject(with: encoded) as? [String: String]
        #expect(deserialized?["dice"] == "d6")
    }

    @Test("Encoding optional dice - nil omits key")
    func encodingOptionalDiceNil() throws {
        let encoded = try JSONEncoder().encode(EncodableOptionalDiceContainer(dice: nil))
        let deserialized = try JSONSerialization.jsonObject(with: encoded) as? [String: String]
        #expect(deserialized?["dice"] == nil)
    }

    @Test("Decoding dice - typical expression")
    func decodingDiceTypicalExpression() throws {
        let json = #"{"dice": "2d6+2"}"#.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(DecodableDiceContainer.self, from: json)
        #expect(decoded.dice is CompoundDice)
    }

    @Test("Decoding dice - dice modifier")
    func decodingDiceDiceModifier() throws {
        let json = #"{"dice": 5}"#.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(DecodableDiceContainer.self, from: json)
        #expect(decoded.dice is DiceModifier)
    }

    @Test("Decoding dice - invalid dice string")
    func decodingDiceInvalidString() {
        let json = #"{"dice": "Hello Dice"}"#.data(using: .utf8)!
        #expect(throws: Error.self) {
            _ = try JSONDecoder().decode(DecodableDiceContainer.self, from: json)
        }
    }

    @Test("Decoding dice if present - typical expression")
    func decodingDiceIfPresentTypicalExpression() throws {
        let json = #"{"dice": "2d6+2"}"#.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(OptionalDiceContainer.self, from: json)
        #expect(decoded.dice is CompoundDice)
    }

    @Test("Decoding dice if present - dice modifier")
    func decodingDiceIfPresentDiceModifier() throws {
        let json = #"{"dice": 5}"#.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(OptionalDiceContainer.self, from: json)
        #expect(decoded.dice is DiceModifier)
    }

    @Test("Decoding dice if present - invalid dice string")
    func decodingDiceIfPresentInvalidString() throws {
        let json = #"{"dice": "Hello Dice"}"#.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(OptionalDiceContainer.self, from: json)
        #expect(decoded.dice == nil)
    }
}

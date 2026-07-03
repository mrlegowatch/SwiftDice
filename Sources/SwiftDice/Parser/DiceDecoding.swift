//
//  DiceDecoding.swift
//  SwiftDice
//
//  Created by Brian Arnold on 11/23/16.
//  Copyright © 2016-2017 Brian Arnold. All rights reserved.
//

import Foundation

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
           let dice = try? DiceParser().parse(string) {
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
            return try? DiceParser().parse(string)
        }

        return nil
    }
}

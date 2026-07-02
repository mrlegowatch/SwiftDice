# SwiftDice  ![Build Status](https://github.com/mrlegowatch/SwiftDice/workflows/Swift/badge.svg)
![Swift Version](https://img.shields.io/badge/Swift-6.0-orange.svg)
![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20macOS-lightgrey.svg)
[![License](https://img.shields.io/github/license/mrlegowatch/SwiftDice)](LICENSE)

A Swift package for representing and rolling dice using standard tabletop RPG notation.

## Overview

SwiftDice provides a `Rollable` protocol and several concrete types covering the full range of dice expressions found in tabletop role-playing games — from a plain d20 to compound expressions like `4d6-L+2`.

## Dice Types

All types conform to `Rollable`, which requires a `roll() -> DiceRoll` method, a `sides` property, and `CustomStringConvertible`. A `DiceRoll` carries both the integer `result` and a human-readable `description` of the roll (e.g. `"(4 + 2 + 6 + 1) - 1"`).

| Type | Description | Example |
|---|---|---|
| `Die` | A single die with a fixed number of sides | `Die.d6.roll()` |
| `Dice` | One or more of the same die | `Dice(.d8, times: 2)` → `"2d8"` |
| `DiceModifier` | A constant value used as a `Rollable` | `DiceModifier(3)` → `"3"` |
| `DroppingDice` | Rolls multiple dice and drops the highest or lowest | `DroppingDice(.d6, times: 4, drop: .lowest)` → `"4d6-L"` |
| `CompoundDice` | Combines two `Rollable` values with a math operator | `CompoundDice(lhs: Dice(.d8), rhs: DiceModifier(2), mathOperator: "+")` → `"d8+2"` |

Supported die sizes: **d4, d6, d8, d10, d12, d20, d100** (also written as `d%`).

## Dice Notation Parser

The `String.parseDice` property converts a dice notation string into a `Rollable` instance. It returns `nil` if the expression cannot be parsed.

```swift
let roll = "4d6-L".parseDice       // DroppingDice — four d6, drop lowest
let roll = "2d8+4".parseDice       // CompoundDice — two d8 plus 4
let roll = "d20".parseDice         // Dice — one d20
let roll = "5d4x10".parseDice      // CompoundDice — five d4 multiplied by 10
```

Supported operators: `+`, `-`, `x`, `*`, `/`

Supported drop modifiers: `-L` (drop lowest), `-H` (drop highest)

Compound expressions are supported: `"2d4+3d12-4"` parses as `((2d4) + (3d12)) - 4`.

## JSON Decoding

`KeyedDecodingContainer` extensions support decoding either a dice notation string or a plain integer directly into a `Rollable`:

```swift
// In your Decodable init:
let hitDice = try container.decode(Rollable.self, forKey: .hitDice)
// Works for JSON values like "d10", "2d6+2", or 5
```

## Usage

```swift
import SwiftDice

// Roll ability scores: 4d6, drop lowest
let abilityRoll = DroppingDice(.d6, times: 4, drop: .lowest)
let result = abilityRoll.roll()
print(result.result)       // e.g. 14
print(result.description)  // e.g. "(3 + 6 + 4 + 5) - 3"

// Parse from a string
if let startingGold = "5d4x10".parseDice {
    print(startingGold.roll().result)  // e.g. 80
}
```

## Background

The dice implementation was originally developed as part of [RolePlayingCore](https://github.com/mrlegowatch/RolePlayingCore). Its evolution is described in three posts on medium.com:

- [So, I made a Dice class](https://medium.com/@mrlegowatch/so-i-made-a-dice-class-1-of-3-9b9bb5c1dc2)
- [So, I tested Dice and added a parser](https://medium.com/@mrlegowatch/so-i-tested-dice-and-added-a-parser-2-of-3-80335e08ddf8)
- [So, Dice is in GitHub now](https://medium.com/@mrlegowatch/so-dice-is-in-github-now-3-3-204fd6c40fc0)

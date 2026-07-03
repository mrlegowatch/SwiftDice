# SwiftDice  [![Swift](https://github.com/mrlegowatch/RolePlayingCore/actions/workflows/swift.yml/badge.svg)](https://github.com/mrlegowatch/RolePlayingCore/actions/workflows/swift.yml)
![Code Coverage](https://codecov.io/gh/mrlegowatch/SwiftDice/branch/development/graph/badge.svg)
![Swift Version](https://img.shields.io/badge/Swift-6.0-orange.svg)
![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20macOS%20%7C%20Linux-lightgrey.svg)
[![License](https://img.shields.io/github/license/mrlegowatch/SwiftDice)](LICENSE)

A Swift package for representing and rolling dice using standard tabletop RPG notation.

## Overview

SwiftDice provides a `Rollable` protocol and several concrete types covering the full range of dice expressions found in tabletop role-playing games — from a plain d20 to compound expressions like `4d6-L+2`.

## Dice Types

All types conform to `Rollable`, which requires a `roll() -> DiceRoll` method and `CustomStringConvertible`. A `DiceRoll` carries both the integer `result` and a human-readable `description` of the intermediate values (e.g. `"((4 + 2 + 6 + 1) - 1)"`).

| Type | Description | Example |
|---|---|---|
| `Dice` | One or more of the same die | `Dice.d8`, `2 * .d8` |
| `FudgeDice` | A Fudge/FATE die with outcomes of -1, 0, or +1 per die rolled | `FudgeDice.dF`, `4 * .dF` |
| `SelectingDice` | Rolls multiple dice, dropping or keeping the highest or lowest | `(4 * .d6).dropping(.lowest)`, `(4 * .d6).keeping(3, .highest)` |
| `CompoundDice` | Combines two `Rollable` values with a math operator | `2 * .d8 + 4`, `2 * .d8 + .d4` |
| `DiceModifier` | A constant value used as a `Rollable` | `DiceModifier(3)` → `"3"` |
| `FudgeDice` | A Fudge/FATE die with outcomes of -1, 0, or +1 per die rolled | `FudgeDice.dF`, `4 * .dF` |

Supported die sizes: **d4, d6, d8, d10, d12, d20, d100** (also written as `d%`) — the standard polyhedral set. Any positive integer is valid when constructing `Dice` directly or parsing from a string.

## Expressions

`Dice` provides static shorthands for the standard polyhedral set, so die types read naturally. The `*`, `+`, and `-` operators and `.dropping(_:)` / `.keeping(_:)` methods compose these into larger expressions:

```swift
Dice.d20                              // d20
2 * .d8                               // 2d8
2 * .d8 + 4                           // 2d8+4
2 * .d8 + .d4                         // 2d8+d4
(4 * .d6).dropping(.lowest)           // 4d6-L
(5 * .d6).dropping(2, .lowest)        // 5d6-L2
(4 * .d6).keeping(3, .highest)        // 4d6kh3 (keep 3 highest of 4d6)
(2 * .d20).keeping(.highest)          // 2d20kh1 (advantage)
(2 * .d6).exploding                   // 2d6! (reroll and add on max)
(4 * .d6).rerolling(below: 1)         // 4d6r1 (reroll 1s once, keep new result)
5 * .d4 * 10                          // 5d4x10
Dice.d100 / 10                        // d%/10
```

Wherever `*` appears, the `Dice.` prefix can be omitted — the operator's `rhs: Dice` signature provides the type context. For example:

```swift
let damage = 2 * .d6 + 3
let fateBonus = 2 * .d8 + .dF
```

## Custom Dice

For dice outside the standard set, construct `Dice` directly or add named shorthands in your own module:

```swift
// Direct construction — works with all operators:
let spellEffect = Dice(sides: 3)          // e.g. Tunnels & Trolls spell dice
let dungeonTable = 5 * Dice(sides: 30)   // e.g. OSR d30 Companion random tables

// Or add named shorthands once:
extension Dice {
    static let d3  = Dice(sides: 3)
    static let d30 = Dice(sides: 30)
}

// Then use them like any standard die:
let tableRoll = (2 * .d30).dropping(.lowest)
```

The parser also accepts any positive integer: `"4d30-L".parseDice` produces a `SelectingDice` over four 30-sided dice.

## Dice Notation Parser

The `String.parseDice` property converts a dice notation string into a `Rollable` instance. It returns `nil` if the expression cannot be parsed.

```swift
let roll = "4d6-L".parseDice       // SelectingDice — four d6, drop lowest
let roll = "4d6kh3".parseDice      // SelectingDice — four d6, keep three highest
let roll = "2d20kh1".parseDice     // SelectingDice — two d20, keep highest (advantage)
let roll = "2d8+4".parseDice       // CompoundDice — two d8 plus 4
let roll = "d20".parseDice         // Dice — one d20
let roll = "5d4x10".parseDice      // CompoundDice — five d4 multiplied by 10
```

Supported operators: `+`, `-`, `x`, `*`, `/`

Supported drop modifiers: `-L` (drop one lowest), `-L2` (drop two lowest), `-H` / `-H2` (same for highest)

Supported keep modifiers: `kh<n>` (keep n highest), `kl<n>` (keep n lowest)

Supported explosion modifier: `!` after the die size (e.g. `2d6!`) — reroll and add on a maximum result, up to 100 extra rolls per die

Supported reroll modifier: `r<n>` after the die size (e.g. `2d6r1`) — reroll once if the initial result is at or below `n`, keeping the new result

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

// Roll ability scores: 4d6, keep 3 highest (drops 1 lowest)
let abilityRoll = (4 * .d6).keeping(3, .highest)
let result = abilityRoll.roll()
print(result.result)       // e.g. 14
print(result.description)  // e.g. "((3 + 6 + 4 + 5) - 3)"

// Attack with advantage: 2d20, keep highest
let attack = (2 * .d20).keeping(.highest)

// Weapon damage: 2d8+4
let damage = 2 * .d8 + 4
print(damage)              // "2d8+4"
print(damage.roll().result) // e.g. 13

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

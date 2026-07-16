# SwiftDice  [![Swift](https://github.com/mrlegowatch/SwiftDice/actions/workflows/swift.yml/badge.svg)](https://github.com/mrlegowatch/SwiftDice/actions/workflows/swift.yml)
![Code Coverage](https://codecov.io/gh/mrlegowatch/SwiftDice/branch/development/graph/badge.svg)
![Swift Version](https://img.shields.io/badge/Swift-6.0-orange.svg)
![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20macOS%20%7C%20Linux-lightgrey.svg)
[![License](https://img.shields.io/github/license/mrlegowatch/SwiftDice)](LICENSE)

A Swift package for representing and rolling dice using standard tabletop RPG notation.

## Installation

Add the package to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/mrlegowatch/SwiftDice", branch: "development"),
],
targets: [
    .target(name: "YourTarget", dependencies: ["SwiftDice"]),
]
```

## Quick Start

```swift
import SwiftDice

// Roll ability scores: 4d6, keep 3 highest
let abilityRoll = (4 * .d6).keeping(3, .highest)
let result = abilityRoll.roll()
print(result.result)       // e.g. 14
print(result.description)  // e.g. "((3 + 6 + 4 + 5) - 3)"

// Attack with advantage: 2d20, keep highest
let attack = (2 * .d20).keeping(.highest)

// Weapon damage: 2d8+4
let damage = 2 * .d8 + 4

// Parse from a notation string
if let gold = try? DiceParser().parse("5d4x10") {
    print(gold.roll().result)  // e.g. 80
}
```

For full API documentation — dice types, notation reference, drop/keep mechanics, exploding dice, JSON encoding, and error handling — build the documentation in Xcode via **Product → Build Documentation**.

## Background

The dice implementation was originally developed as part of [RolePlayingCore](https://github.com/mrlegowatch/RolePlayingCore). Its evolution is described in three posts on medium.com:

- [So, I made a Dice class](https://medium.com/@mrlegowatch/so-i-made-a-dice-class-1-of-3-9b9bb5c1dc2)
- [So, I tested Dice and added a parser](https://medium.com/@mrlegowatch/so-i-tested-dice-and-added-a-parser-2-of-3-80335e08ddf8)
- [So, Dice is in GitHub now](https://medium.com/@mrlegowatch/so-dice-is-in-github-now-3-3-204fd6c40fc0)

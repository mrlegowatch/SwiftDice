# ``SwiftDice``

Roll standard tabletop RPG dice and compound expressions in Swift.

## Overview

SwiftDice provides a ``Rollable`` protocol and concrete types covering the full range of dice
expressions used in tabletop role-playing games — from a plain `d20` to compound expressions
like `4d6-L+2`.

```swift
import SwiftDice

// Roll ability scores: 4d6, keep 3 highest
let abilityRoll = (4 * .d6).keeping(3, .highest)
let result = abilityRoll.roll()
print(result.result)       // e.g. 14
print(result.description)  // e.g. "((3 + 6 + 4 + 5) - 3)"

// Parse from a notation string
let parser = DiceParser()
let damage = try parser.parse("2d8+4")
print(damage.roll().result) // e.g. 13
```

## Topics

### Protocols and Results

- ``Rollable``
- ``DiceRoll``

### Dice Types

- ``Dice``
- ``CompoundDice``
- ``SelectingDice``
- ``DiceModifier``
- ``FudgeDice``

### Parsing

- ``DiceParser``
- ``DiceParseFailure``
- ``DiceParseError``

### Articles

- <doc:GettingStarted>
- <doc:DiceNotation>
- <doc:ErrorHandling>

# Getting Started with SwiftDice

Add dice rolling to your Swift app in minutes.

## Overview

SwiftDice models dice expressions as composable Swift values. You start with a ``Dice`` type,
combine it using operators, and call `roll()` to get a result. All dice types conform to the
``Rollable`` protocol, so you can store and pass expressions without committing to a concrete type.

## Basic Dice

The standard polyhedral set is available as static shorthands on ``Dice``:

```swift
Dice.d4   // four-sided die
Dice.d6   // six-sided die
Dice.d8
Dice.d10
Dice.d12
Dice.d20
Dice.d100   // also written as d%
```

Use the `*` operator to roll multiple dice of the same type. When `*` appears on the left,
the `Dice.` prefix can be omitted — Swift infers the type from the operator signature:

```swift
let roll = 4 * .d6    // equivalent to 4 * Dice.d6
```

## Compound Expressions

Combine dice with arithmetic operators to build compound expressions:

```swift
2 * .d8 + 4      // 2d8+4  — two d8 plus a constant
2 * .d8 + .d4    // 2d8+d4 — two d8 plus one d4
Dice.d12 - 2     // d12-2  — one d12 minus 2
5 * .d4 * 10     // 5d4x10 — five d4 multiplied by 10
Dice.d100 / 10   // d%/10  — percentile die divided by 10
```

Operator precedence follows standard arithmetic: `*`, `x`, and `/` bind before `+` and `-`.
Use parentheses to override:

```swift
let result = try DiceParser().parse("(2d6+3)*2")  // (2d6+3)*2, not 2d6+(3*2)
```

## Drop and Keep

``SelectingDice`` rolls a pool and sums only a subset. Use the `.dropping(_:)` and
`.keeping(_:)` methods on ``Dice``:

```swift
(4 * .d6).dropping(.lowest)     // 4d6-L   — roll 4d6, drop the lowest
(5 * .d6).dropping(2, .lowest)  // 5d6-L2  — roll 5d6, drop two lowest
(4 * .d6).keeping(3, .highest)  // 4d6kh3  — roll 4d6, keep three highest
(2 * .d20).keeping(.highest)    // 2d20kh1 — advantage: keep the higher of two d20
(2 * .d20).keeping(.lowest)     // 2d20kl1 — disadvantage: keep the lower
```

## Custom Dice

For die sizes outside the standard set, construct ``Dice`` directly or add named shorthands
in your own module:

```swift
// Direct construction — works with all operators:
let spellEffect = Dice(sides: 3)
let tableRoll   = 5 * Dice(sides: 30)

// Or add named shorthands once:
extension Dice {
    static let d3  = Dice(sides: 3)
    static let d30 = Dice(sides: 30)
}

let drop = (2 * .d30).dropping(.lowest)
```

## Reading Roll Results

Every `roll()` call returns a ``DiceRoll`` with two properties:

- `result` — the integer total; use this for game logic
- `description` — a breakdown of individual die values; use this for display

```swift
let roll = (4 * .d6).dropping(.lowest).roll()
print(roll.result)       // e.g. 14
print(roll.description)  // e.g. "((3 + 6 + 4 + 5) - 3)"
```

## Pool Mechanics with rollAll()

``Dice/rollAll()`` returns per-die results before they are summed, enabling client-side pool
mechanics such as counting successes:

```swift
let pool = 5 * Dice.d10
let threshold = 6
let successes = pool.rollAll().filter { $0 >= threshold }.count
print("Successes: \(successes)")
```

## JSON Encoding and Decoding

SwiftDice extends `KeyedEncodingContainer` and `KeyedDecodingContainer` to encode any
``Rollable`` as its dice notation string and decode it back:

```swift
// Encoding — in your Encodable conformance:
try container.encode(hitDice, forKey: .hitDice)           // writes e.g. "2d6+2"
try container.encodeIfPresent(bonusDice, forKey: .bonus)  // omits key if nil

// Decoding — in your Decodable conformance:
let hitDice = try container.decode(Rollable.self, forKey: .hitDice)
// accepts JSON values like "d10", "2d6+2", or the integer 5
```

The encoded value is the `description` of the ``Rollable`` — the same notation string that
``DiceParser`` can round-trip back to an equivalent instance.

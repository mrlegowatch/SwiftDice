# Dice Notation Reference

The complete set of expressions that ``DiceParser`` accepts.

## Overview

``DiceParser`` converts dice notation strings to ``Rollable`` instances. This article documents
every construct the parser supports, with examples of each.

## Die Expressions

A basic die expression is an optional count followed by `d` (or `D`) and a side count:

| Notation | Meaning |
|---|---|
| `d6` | One six-sided die |
| `2d6` | Two six-sided dice (sum) |
| `d%` | One percentile die (also written as `d100`) |
| `dF` | One Fudge die (outcome: −1, 0, or +1) |
| `4dF` | Four Fudge dice |

Any positive integer is valid as a side count. The count defaults to 1 if omitted.

## Modifiers

Modifiers follow the die expression and alter how dice are rolled:

| Modifier | Notation | Example | Meaning |
|---|---|---|---|
| Drop lowest | `-L` | `4d6-L` | Drop one lowest result |
| Drop lowest n | `-L<n>` | `5d6-L2` | Drop n lowest results |
| Keep highest | `kh<n>` | `4d6kh3` | Keep n highest results |
| Keep lowest | `kl<n>` | `2d20kl1` | Keep n lowest results |
| Drop highest | `-H` | `3d4-H` | Drop one highest result |
| Drop highest n | `-H<n>` | `5d4-H2` | Drop n highest results |
| Exploding | `!` | `2d6!` | On a maximum roll, roll again and add |
| Reroll | `r<n>` | `2d6r1` | Reroll once if the initial result is ≤ n |

Exploding and reroll can be combined: `2d6!r1` (exploding d6 that also rerolls initial 1s).
Drop and keep modifiers are mutually exclusive on a single die expression.
Fudge dice (`dF`) do not support any of these modifiers.

## Compound Expressions

Die expressions can be combined with arithmetic operators:

| Operator | Notation | Example | Meaning |
|---|---|---|---|
| Add | `+` | `2d8+4` | Sum two expressions |
| Subtract | `-` | `d12-2` | Difference of two expressions |
| Multiply | `x` or `*` | `5d4x10` | Product of two expressions |
| Divide | `/` | `d100/10` | Integer quotient (truncates toward zero) |

Operator precedence follows standard arithmetic — `x`, `*`, and `/` bind before `+` and `-`:

```
2d4+d12-2+5    →  ((2d4 + d12) - 2) + 5
2d6+3*2        →  2d6 + (3*2)          result range 8–18
```

## Parentheses

Parentheses override operator precedence:

```
(2d6+3)*2      →  (2d6+3) * 2          result range 10–30
```

## Whitespace

Whitespace and newlines between tokens are ignored:

```
3d4 - L + d12 - 2 + 5    →  valid, same as "3d4-L+d12-2+5"
```

## Constants and Negative Modifiers

A bare integer is a valid expression:

```
5       →  constant 5
-3      →  constant −3 (only valid at the start of an expression)
1+3     →  constant 4
```

## Parser Usage

```swift
let parser = DiceParser()

let roll     = try parser.parse("4d6-L")   // SelectingDice
let compound = try parser.parse("2d8+4")   // CompoundDice
let constant = try parser.parse("-3")      // DiceModifier(-3)
```

See <doc:ErrorHandling> for how to handle parse failures.

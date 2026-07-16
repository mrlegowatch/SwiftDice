# Handling Parse Errors

Catch and interpret ``DiceParseFailure`` for robust error handling.

## Overview

``DiceParser/parse(_:)`` throws ``DiceParseFailure`` when the expression is invalid.
`DiceParseFailure` pairs a specific error kind (``DiceParseError``) with the original input
string and the position where the problem was detected, enabling both programmatic branching
and human-readable diagnostics.

## Catching a Failure

```swift
let parser = DiceParser()

do {
    let roll = try parser.parse("2d4H")
} catch let failure as DiceParseFailure {
    // Inspect the error kind programmatically
    print(failure.error)   // DiceParseError.missingMinus

    // Or display the full diagnostic
    print(failure.localizedDescription)
    // Drop notation requires a preceding '-' (e.g. "4d6-L", not "4d6L")
    // 2d4H
    //    ^
}
```

## Compiler-Style Diagnostics

`DiceParseFailure.errorDescription` produces a three-line diagnostic:

1. A human-readable description of the error
2. The original input string
3. A caret (`^`) positioned at the problem offset

```
Expected a number, 'F', or '%' after 'd' (e.g. 'd6', 'd20', 'd%', 'dF')
3d
  ^
```

Use `failure.input` and `failure.offset` directly if you need to highlight the problem
position in your own UI rather than printing the text diagnostic.

## Branching on Error Kind

Switch on `failure.error` to handle specific cases programmatically:

```swift
} catch let failure as DiceParseFailure {
    switch failure.error {
    case .missingExpression:
        // User submitted an empty field
        showEmptyInputWarning()
    case .invalidCharacter(let char):
        // Unsupported character — e.g. a variable name or typo
        showError("'\(char)' is not part of dice notation")
    default:
        showError(failure.localizedDescription)
    }
}
```

## All Error Cases

| Case | Thrown when |
|---|---|
| `invalidCharacter(String)` | A character that isn't part of dice notation is encountered |
| `invalidDieSides(Int)` | The die side count is not a positive integer (e.g. `d0`) |
| `missingMinus` | A drop token (`L`/`H`) appears without a preceding `-` |
| `missingSimpleDice` | A modifier follows something it can't apply to (e.g. on Fudge dice, or a bare `!`) |
| `missingDieSides` | A `d` token is not followed by a number, `F`, or `%` |
| `missingExpression` | The input is empty or ends with an incomplete operator |
| `consecutiveDiceExpressions` | A complete expression is followed by an unexpected token |
| `missingClosingParen` | An opening `(` has no matching `)` |

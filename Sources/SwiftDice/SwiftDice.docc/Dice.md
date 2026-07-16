# ``Dice``

@Metadata {
    @DocumentationExtension(mergeBehavior: append)
}

## Topics

### Standard Dice

- ``d4``
- ``d6``
- ``d8``
- ``d10``
- ``d12``
- ``d20``
- ``d100``

### Creating Dice

- ``init(sides:times:exploding:rerollThreshold:)``

### Properties

- ``sides``
- ``times``
- ``isExploding``
- ``rerollThreshold``
- ``description``

### Rolling

- ``roll()``
- ``rollAll()``

### Modifiers

- ``exploding``
- ``rerolling(below:)``

### Drop and Keep

- ``dropping(_:)``
- ``dropping(_:_:)``
- ``keeping(_:)``
- ``keeping(_:_:)``

### Operators

- ``*(lhs:rhs:)``

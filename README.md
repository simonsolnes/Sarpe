# Sarpe
/sɑːrp/

Haskell-like parser combinators in a Schwifty manner

**Toy project**  
If you are looking for something more production-ready, I would reccomend: [davedufresne/SwiftParsec](https://github.com/davedufresne/SwiftParsec)

Most the theory is from Scott Wlaschin's work on parser combinators with F#. I really reccomend his talk ["Understanding parser combinators: a deep dive"](https://www.youtube.com/watch?v=RDalzi7mhdY). It was my first intro to combinators and what peaked my interest.

## What are parser combinators
Parsers combinators are parsers that be semantically combined with other parsers. Such as:

- Presedence: `parser1.preceded(by: parser2)`
- Repitition: `parser1.repeat(4...)`
- Branching: `either(parser1, parser2)`

Parser combinators are also monads, which mean we can bind them to a function that returns a parser, and apply it to the result.

- Map: `parseDigits.map { Int($0) }`
- Optional: `parser.optional()` 
- Application: `parser1.apply(parser2)`

The most important parser is `satisfy`, which takes one element and returns `.success` if it matches the predicate function.

*Example*: `satsify {"a"..."z" ~= $0}` (takes a character if it's a lowercase letter)

The whole parser library can be built from `bind` and `satisfy`, but with supporting backtrack prevention, limits and for optimalization reasons, there are a few custom functions.

Combinators are very modular, so one can implement the parts and combine it to a bigger parser.

## Features

- **Swifty**: Focus on creating parsers with Swift's expressiveness rather having a big API surface
- **No operator overloading**: a lot of monadic parser libraries use `<&>`, '>>=`, `<|>` etc. to combine parsers. I prefer words.
- **Few primitives**: Makes it easy to optimize
- **Generic**: Not limited to strings
- **Value oriented**: Parsers are values, and they are immutable.
- **Backtrack prevention**:
- **Buffer limit aware**:


## Examples

### Cat or dog

```swift
enum Animal {
    case cat
    case dog
}
let parser = either(
    literal("cat").to(Animal.cat),
    literal("dog").to(Animal.dog)
)

assert(parser.parse("cat") == .success(.cat, ""))
```

### `Bind` example

```swift
enum Number: Equatable {
    case signed(Int)
    case unsigned(UInt)
}

let number = char("-").optional().bind { minus in
    let unsignedNumber = satisfy { "0" ... "9" ~= $0 }
        .repeat(0...)
        .map { String($0) }

    if let minus {
        return unsignedNumber
            .map { -Int($0)! }
            .map { Number.signed($0) }
    } else {
        return unsignedNumber
            .map { UInt($0)! }
            .map { Number.unsigned($0) }
    }
}

assert(number.parse("3") == .limit(.unsigned(3), ""))
assert(number.parse("-0345somethingElse") == .success(.signed(-345), "somethingElse"))
```

### JSON array

Where `jsonWhitspace` and `jsonValue` are already declared.

```swift
let jsonArray = either(
    jsonWhitespace
        .preceded(by: char("["))
        .terminated(by: char("]"))
        .to(JSON.array([])),

    serial(
        jsonValue(),
        jsonValue()
            .preceded(by: char(","))
            .repeat(0...)
    ).map { first, rest in
        [first] + rest
    }
    .preceded(by: char("["))
    .terminated(by: char("]"))
    .map { JSON.array($0) }
)
```

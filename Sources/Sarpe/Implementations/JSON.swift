public enum JSON: Equatable {
    case int(Int)
    case uint(UInt)
    case double(Double)
    case string(String)
    case bool(Bool)
    case null
    case object([String: JSON])
    case array([JSON])

    public static func parse(_ input: Substring) -> Parse<Substring, JSON> {
        either(jsonObject, jsonArray).parse(input)
    }

    public static func parse(_ input: String) -> Parse<Substring, JSON> {
        either(jsonObject, jsonArray).parse(input.suffix(from: input.startIndex))
    }
}

func jsonValue() -> Parser<Substring, JSON> {
    either(jsonString, jsonNumber, jsonBool, jsonNull, jsonArray, jsonObject)
        .preceded(by: jsonWhitespace)
        .terminated(by: jsonWhitespace)
}

let jsonNull = literal("null")
    .abstain()
    .to(JSON.null)

let jsonBool = either(literal("true"), literal("false"))
    .abstain()
    .mapOption { Bool(String($0)) }
    .map { JSON.bool(Bool(String($0))!) }

let jsonWhitespace = satisfy { " \n\r\t".contains($0) }
    .repeat()
    .map { String($0) }

let jsonArray =
    lazyParser {
        either(
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
    }

let keyValuePair = char(":")
    .separates(
        before: jsonString
            .preceded(by: jsonWhitespace)
            .terminated(by: jsonWhitespace),
        after: jsonValue()
    )
let jsonObject = lazyParser {
    either(
        jsonWhitespace
            .between(char("{"), char("}"))
            .to([String: JSON]()),

        serial(
            keyValuePair,
            keyValuePair
                .preceded(by: char(","))
                .repeat(0...)
        )
        .preceded(by: char("{"))
        .terminated(by: char("}"))
        .map { first, rest in
            [first] + rest
        }
        .map { (list: [(JSON, JSON)]) in
            list.reduce(into: [:]) { object, keyPair in
                if case let .string(key) = keyPair.0 {
                    let val = keyPair.1
                    object[key] = val
                }
            }
        }
    )
    .map { JSON.object($0) }
}

let jsonString = {
    let quote = char(#"""#)
    let backslash = char(#"\"#)

    let hex = Parser.from("0"..."9", "a"..."f", "A"..."F")

    let unicodeHex = hex
        .repeat(4)
        .map { String($0) }
        .mapOption { UInt16($0, radix: 16) }
        .mapOption { Unicode.Scalar($0) }
        .map { String($0) }

    return either(
        satisfy { $0 != "\"" && $0 != "\\" }
            .repeat(1...)
            .map { String($0) }
            .label("parse any char"),
        backslash
            .precedes(
                either(
                    either(
                        quote,
                        backslash,
                        satisfy { "/bfnrt".contains($0) }
                    )
                    .map(on: [
                        "\"": "\"",
                        "\\": "\\",
                        "/": "/",
                        "b": "\u{08}", // BS backspace
                        "f": "\u{0C}", // FF Form feed
                        "n": "\n", // LF Line feed
                        "r": "\r", // CR Carriage return
                        "t": "\t", // HT Horizontal tab
                    ]),
                    unicodeHex
                        .preceded(by: char("u"))
                )
            )

            .label("parse k")
    )
    .repeat(0...)
    .preceded(by: char(#"""#))
    .terminated(by: char(#"""#))
    .map { $0.joined() }
    .map { JSON.string($0) }
}()

let jsonNumber = serial(
    literal("-")
        .optional()
        .map { $0 ?? "" },

    either(
        literal("0").map { String($0) },
        sequence(
            satisfy { "1"..."9" ~= $0 }.map { String($0) },
            digit.repeat(0...).map { String($0) }
        ).map { $0.joined() }
    ),

    char(".").precedes(
        digit
            .repeat(1...)
            .map { String($0) }
    )
    .optional()
    .map { $0 ?? "" },

    either(char("e"), char("E")).precedes(
        sequence(
            either(literal("+"), literal("-")).optional().map { String($0 ?? "") },
            digit.repeat(1...).map { String($0) }
        ).map { $0.joined() }
    ).optional()
        .map { $0.map { "e" + $0 } }
        .map { $0 ?? "" }
)
.map(convertNumber)

private let convertNumber = { (_ result: (String.SubSequence, String, String, String)) -> JSON in
    let (minusS, numberS, fractionS, exponentS) = result
    if fractionS.isEmpty, exponentS.isEmpty {
        if minusS.isEmpty {
            return JSON.uint(UInt(numberS)!)
        } else {
            return JSON.int(-(Int(numberS)!))
        }
    } else {
        let thing = [String(minusS), numberS, ".", fractionS, exponentS].joined()
        return JSON.double(Double(thing)!)
    }
}

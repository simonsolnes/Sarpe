public func satisfy(_ predicate: @escaping (Character) -> Bool) -> Parser<Substring, Character> {
    Parser { input in
        if input.count != 0 {
            if predicate(input[input.startIndex]) {
                .success(input[input.startIndex], input[input.index(input.startIndex, offsetBy: 1)...])
            } else {
                .retreat("Char: '\(input[input.startIndex])' did not match predicate")
            }
        } else {
            Parse<Substring, Character>.limit(nil, input)
        }
    }
}

// Takewhile: https://swiftinit.org/reference/swift/substring

public func char(_ character: Character) -> Parser<Substring, Character> {
    satisfy { $0 == character }
}

public let digit = satisfy { "0" ... "9" ~= $0 }

public func literal<T: Collection>(_ expected: T) -> Parser<T.SubSequence, T.SubSequence> where T.Element: Equatable {
    Parser {
        let input = $0
        if input.count == 0 {
            return .limit(nil, input)
        }
        var expectedIter = expected.makeIterator()
        var inputIter = input.makeIterator()
        var count = 0
        while true {
            if let expectedItem = expectedIter.next() {
                if let inputItem = inputIter.next() {
                    if expectedItem != inputItem {
                        return .retreat("no good")
                    }
                } else {
                    let res = input[..<input.index(input.startIndex, offsetBy: count)]
                    let sur = input[input.index(input.startIndex, offsetBy: count)...]
                    return .limit(res, sur)
                }

            } else {
                let res = input[..<input.index(input.startIndex, offsetBy: count)]
                let sur = input[input.index(input.startIndex, offsetBy: count)...]
                return .success(res, sur)
            }
            count += 1
        }
    }
}

public func eof<T: Collection>() -> Parser<T, T> {
    Parser {
        if $0.count == 0 {
            .success($0, $0)
        } else {
            .retreat("not end")
        }
    }
}

/*
public func takeWhile(max: Int?, _ predicate: @escaping (Character) -> Bool) -> Parser<Substring, Substring> {
    Parser {
        var count = 0
        for index in $0.indices {
            print(index)
        }
        return Parse<Substring, Substring>.halt("")
    }
}
*/

extension Parser<Substring, Character> {
    // TODO: make generic
    static func from(_ charRanges: ClosedRange<Character>...) -> Parser<Substring, Character> {
        either(charRanges.map { range in satisfy { char in range ~= char }})
    }
}

func lazyParser<I, O>(_ fun: @escaping () -> Parser<I, O>) -> Parser<I, O> {
    Parser { input in
        fun().parse(input)
    }
}

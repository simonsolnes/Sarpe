func curry<A, B, R>(_ function: @escaping (A, B) -> R) -> (A) -> (B) -> R {
    { paramA in { paramB in function(paramA, paramB) } }
}

private func either<I, O>(_ parser1: Parser<I, O>, _ parser2: Parser<I, O>) -> Parser<I, O> {
    return Parser<I, O> {
        switch parser1.parse($0) {
        case let .success(res, sur):
            return .success(res, sur)
        case .retreat:
            return parser2.parse($0)
        case let .halt(reason):
            return .halt(reason)
        case let .limit(res, sur):
            switch parser2.parse($0) {
            case let .success(res2, sur2):
                return .success(res2, sur2)
            case .retreat:
                return .limit(res, sur)
            case let .halt(reason):
                return .halt(reason)
            case let .limit(res2, sur2):
                if let res {
                    return .limit(res, sur)
                } else if let res2 {
                    return .limit(res2, sur2)
                } else {
                    return .limit(nil, $0)
                }
            }
        }
    }
}

func either<I, O>(_ parsers: [Parser<I, O>]) -> Parser<I, O> {
    parsers.reduce(Parser.thatRetreats(label: "None of the parsers matched"), either)
}

func either<I, O>(_ parsers: Parser<I, O>...) -> Parser<I, O> {
    either(parsers)
}

func lift<I, A, B, R>(_ function: @escaping (A, B) -> R) -> (Parser<I, A>, Parser<I, B>) -> Parser<I, R> {
    { parserA, parserB in
        Parser(value: curry(function))
            .apply(value: parserA)
            .apply(value: parserB)
    }
}

func serial<I, O1, O2>(_ parser1: Parser<I, O1>, _ parser2: Parser<I, O2>) -> Parser<I, (O1, O2)> {
    parser1.bind { result1 in
        parser2.bind(withLimit: true) { result2 in
            Parser(value: (result1, result2))
        }
    }
}

func sequence<I, O>(_ parsers: [Parser<I, O>]) -> Parser<I, [O]> {
    if let first = parsers.first {
        return lift { (first: O, rest: [O]) in
            [first] + rest
        }(first, sequence(Array(parsers.dropFirst())))
    } else {
        return Parser<I, [O]>(value: [])
    }
}

func sequence<I, O>(_ parsers: Parser<I, O>...) -> Parser<I, [O]> {
    sequence(parsers)
}

func serial<I, O1, O2, O3>(
    _ parser1: Parser<I, O1>,
    _ parser2: Parser<I, O2>,
    _ parser3: Parser<I, O3>
) -> Parser<I, (O1, O2, O3)> {
    serial(serial(parser1, parser2), parser3).map { ($0.0, $0.1, $1) }
}

func serial<I, O1, O2, O3, O4>(
    _ parser1: Parser<I, O1>,
    _ parser2: Parser<I, O2>,
    _ parser3: Parser<I, O3>,
    _ parser4: Parser<I, O4>
) -> Parser<I, (O1, O2, O3, O4)> {
    serial(serial(parser1, parser2), serial(parser3, parser4)).map { ($0.0, $0.1, $1.0, $1.1) }
}

public typealias Stack = [Double]
public typealias RpnOperation = (Stack) -> Stack

func bind(_ fun: @escaping (Double) -> RpnOperation) -> RpnOperation {
    { stack in
        fun(stack.last ?? 0)(stack.dropLast())
    }
}

func push(_ value: Stack) -> RpnOperation {
    { stack in stack + value }
}

func map(_ fun: @escaping (Double) -> Double) -> RpnOperation {
    bind { val in push([fun(val)]) }
}

func collapse(_ fun: @escaping (Double, Double) -> Double) -> RpnOperation {
    bind { x in map { y in fun(y, x) } }
}

let number = char("-").optional().bind { minus in
    either(
        digit
            .repeat(1...)
            .map { String($0) },
        serial(
            digit
                .repeat(0...)
                .map { String($0) },
            digit
                .repeat(1...)
                .preceded(by: char("."))
                .map { String($0) }
        )
        .map { integer, decimal in
            integer + "." + decimal
        }
    )
    .map {
        if let minus {
            return -Double($0)!
        } else {
            return Double($0)!
        }
    }
    .map {
        push([$0])
    }
}

let operation = either(
    literal("+").to(collapse { y, x in y + x }),
    literal("-").to(collapse { y, x in y - x }),
    literal("chs").to(map { x in -x }),
    literal("swp").to(bind { x in bind { y in push([x, y]) } })
)

let evaluate = { input in
    either(
        number,
        operation
    )
    .preceded(by: char(" ").repeat(0...))
    .repeat(0...)
    .map { (instructions: [RpnOperation]) in
        instructions.reduce([]) { stack, instruction in
            instruction(stack)
        }
    }
    .parse(input)
}

public func ttt() {
    print(evaluate("3 4 swp -"))
}

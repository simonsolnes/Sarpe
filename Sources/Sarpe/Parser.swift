// https://stackoverflow.com/questions/40031010/how-to-use-first-head-and-rest-tail-with-swift
public struct Parser<I, O>: CustomStringConvertible {
  public func parse(_ input: I) -> Parse<I, O> {
    self.parseFunc(input)
  }

  let parseFunc: (_ input: I) -> Parse<I, O>
  let label: String
  public var description: String { self.label }

  public init(_ parseFn: @escaping (I) -> Parse<I, O>, label: String = "") {
    self.parseFunc = parseFn
    self.label = label
  }

  public init(value: O, label: String = "") {
    self.parseFunc = { .success(value, $0) }
    self.label = label
  }

  static func thatRetreats(label: String? = nil) -> Parser<I, O> {
    Parser { _ in
      .retreat(label ?? "failing parser")
    }
  }

  public func label(_ description: String) -> Parser<I, O> {
    Parser(self.parseFunc, label: description)
  }

  public func apply<V, R>(value: Parser<I, V>) -> Parser<I, R> where O == (V) -> R {
    self.bind { fun in value.map(fun) }
  }

  public func map<R>(withLimit: Bool = true, _ function: @escaping (O) -> R) -> Parser<I, R> {
    self.bind(withLimit: withLimit) { input in
      Parser<I, R>(value: function(input))
    }
  }

  public func mapOption<R>(withLimit: Bool = true, _ function: @escaping (O) -> R?) -> Parser<I, R>
  {
    self.bind(withLimit: withLimit) { input in
      if let val = function(input) {
        return Parser<I, R>(value: val)
      } else {
        return Parser<I, R>.thatRetreats()
      }
    }
  }

  public func map<R>(on dict: [O: R]) -> Parser<I, R> {
    self.mapOption { dict[$0] }
  }

  public func to<R>(_ value: R) -> Parser<I, R> {
    self.map { _ in value }
  }

  public func bind<R>(withLimit: Bool = true, _ function: @escaping (O) -> Parser<I, R>) -> Parser<
    I, R
  > {
    Parser<I, R> { input in
      switch self.parse(input) {
      case let .success(res, sur):
        function(res).parse(sur)
      case let .limit(res, sur) where res != nil && withLimit:
        switch function(res!).parse(sur) {
        case let .success(res2, sur2):
          .limit(res2, sur2)
        case let other:
          other
        }
      case .limit:
        .limit(nil, input)
      case let .retreat(reason):
        .retreat(reason)
      case let .halt(reason):
        .halt(reason)
      }
    }
  }

  public func optional() -> Parser<I, O?> {
    Parser<I, O?> {
      switch self.parse($0) {
      case let .success(res, sur):
        .success(.some(res), sur)
      case .retreat:
        .success(nil, $0)
      case let .limit(res, sur) where res != nil:
        .limit(res, sur)
      case .limit:
        .success(nil, $0)
      case let .halt(reason):
        .halt(reason)
      }
    }
  }
}

/// # Repetition
extension Parser {
  public func `repeat`(_ exactRepeats: Int) -> Parser<I, [O]> {
    sequence(Array(repeating: self, count: exactRepeats))
  }

  public func `repeat`(_ from: PartialRangeFrom<Int>) -> Parser<I, [O]> {
    serial(
      self.repeat(from.lowerBound),
      self.repeat()
    ).map(+)
  }

  public func `repeat`(_ through: PartialRangeThrough<Int>) -> Parser<I, [O]> {
    self.repeat(max: through.upperBound)
  }

  public func `repeat`(_ upTo: PartialRangeUpTo<Int>) -> Parser<I, [O]> {
    self.repeat(max: upTo.upperBound - 1)
  }

  public func `repeat`(_ bounds: Range<Int>) -> Parser<I, [O]> {
    self.repeat(bounds.lowerBound...bounds.upperBound - 1)
  }

  public func `repeat`(_ bounds: ClosedRange<Int>) -> Parser<I, [O]> {
    serial(
      self.repeat(bounds.lowerBound),
      self.repeat(max: bounds.upperBound - bounds.lowerBound)
    ).map(+)
  }

  public func `repeat`(max: Int? = nil) -> Parser<I, [O]> {
    Parser<I, [O]> {
      var count = 0
      var retval: [O] = []
      var remainder = $0
      while true {
        if let max {
          if count == max {
            return .success(retval, remainder)
          }
        }
        switch self.parse(remainder) {
        case let .success(res, sur):
          retval += [res]
          remainder = sur
        case let .limit(res, sur):
          if let res {
            return .limit(retval + [res], sur)
          } else {
            return .limit(retval, remainder)
          }
        case let .halt(reason):
          return .halt(reason)
        case .retreat:
          return .success(retval, remainder)
        }
        count += 1
      }
    }
  }
}

/// # Control Flow
extension Parser {
  /// Halt a parser that retreats
  public func halts(_ reason: String? = nil) -> Parser<I, O> {
    Parser {
      switch self.parse($0) {
      case let .retreat(retreatReason):
        .halt(reason ?? retreatReason)
      case let other:
        other
      }
    }
  }

  /// Convert limit of `Some` to `nil`
  public func abstain() -> Parser<I, O> {
    Parser {
      switch self.parse($0) {
      case let .limit(res, _) where res != nil:
        .limit(nil, $0)
      case let other:
        other
      }
    }
  }

  /// Turn a limit with a non-`nil` value to success
  public func saturate() -> Parser<I, O> {
    Parser {
      switch self.parse($0) {
      case let .limit(res, sur) where res != nil:
        .success(res!, sur)
      case let other:
        other
      }
    }
  }
  /// Fails if there are remaining
  public func complete() -> Parser<I, O> {
    Parser {
      switch self.parse($0) {
      case let .limit(res, _) where res == nil:
        .retreat("Couldn't complete")
      case let other:
        other
      }
    }
  }
}

/// # Presidence
extension Parser {
  public func preceded<W>(by president: Parser<I, W>) -> Parser<I, O> {
    serial(president, self).map { $0.1 }
  }

  public func terminated<W>(by terminator: Parser<I, W>) -> Parser<I, O> {
    serial(self, terminator).map { $0.0 }
  }

  public func precedes<K>(_ successor: Parser<I, K>) -> Parser<I, K> {
    successor.preceded(by: self)
  }

  public func terminates<K>(_ predecessor: Parser<I, K>) -> Parser<I, K> {
    predecessor.terminated(by: self)
  }

  public func separates<K1, K2>(before: Parser<I, K1>, after: Parser<I, K2>) -> Parser<I, (K1, K2)>
  {
    serial(before, self, after).map { ($0.0, $0.2) }
  }

  public func between<W1, W2>(_ before: Parser<I, W1>, _ after: Parser<I, W2>) -> Parser<I, O> {
    self
      .preceded(by: before)
      .terminated(by: after)
  }
}

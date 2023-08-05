public enum Parse<Input, Output> {
    case success(Output, Input)
    case retreat(String)
    case halt(String)
    case limit(Output?, Input)
    func isRetreat() -> Bool {
        if case .retreat = self {
            true
        } else {
            false
        }
    }

    func isHalt() -> Bool {
        if case .halt = self {
            true
        } else {
            false
        }
    }
}

extension Parse: Equatable where Input: Equatable, Output: Equatable {
    public static func == (lhs: Parse<Input, Output>, rhs: Parse<Input, Output>) -> Bool
        where Input: Equatable, Output: Equatable
    {
        switch lhs {
        case let .success(resLhs, surLhs):
            switch rhs {
            case let .success(resRhs, surRhs):
                resLhs == resRhs && surLhs == surRhs
            default:
                false
            }
        case let .retreat(reasonLhs):
            switch rhs {
            case let .retreat(reasonRhs):
                reasonLhs == reasonRhs
            default:
                false
            }
        case let .halt(reasonLhs):
            switch rhs {
            case let .halt(reasonRhs):
                reasonLhs == reasonRhs
            default:
                false
            }
        case let .limit(resLhs, surLhs):
            switch rhs {
            case let .limit(resRhs, surRhs):
                (resLhs == resRhs) && (surLhs == surRhs)
            default:
                false
            }
        }
    }
}

enum Parse<Input, Output> {
    case success(Output, Input)
    case retreat(String)
    case halt(String)
    case limit(Output?, Input)
    func isRetreat() -> Bool {
        if case .retreat = self {
            return true
        } else {
            return false
        }
    }

    func isHalt() -> Bool {
        if case .halt = self {
            return true
        } else {
            return false
        }
    }
}

extension Parse: Equatable where Input: Equatable, Output: Equatable {
    static func == (lhs: Parse<Input, Output>, rhs: Parse<Input, Output>) -> Bool
        where Input: Equatable, Output: Equatable
    {
        switch lhs {
        case let .success(resLhs, surLhs):
            switch rhs {
            case let .success(resRhs, surRhs):
                return resLhs == resRhs && surLhs == surRhs
            default:
                return false
            }
        case let .retreat(reasonLhs):
            switch rhs {
            case let .retreat(reasonRhs):
                return reasonLhs == reasonRhs
            default:
                return false
            }
        case let .halt(reasonLhs):
            switch rhs {
            case let .halt(reasonRhs):
                return reasonLhs == reasonRhs
            default:
                return false
            }
        case let .limit(resLhs, surLhs):
            switch rhs {
            case let .limit(resRhs, surRhs):
                return (resLhs == resRhs) && (surLhs == surRhs)
            default:
                return false
            }
        }
    }
}

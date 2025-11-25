import Foundation

public enum BluxError: Error {
    case LengthOutOfRangeBetween(String, any Comparable, any Comparable)
    case LengthOutOfRangeGe(String, any Comparable)
    case ValueOutOfRangeBetween(String, any Comparable, any Comparable)
    case ValueOutOfRangeGe(String, any Comparable)
    case InvalidQuantity
}

extension BluxError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .LengthOutOfRangeBetween(varName, min, max):
            return "The length of `\(varName)` must be between \(min) and \(max)."
        case let .LengthOutOfRangeGe(varName, min):
            return "The length of `\(varName)` must be greater than or equal to \(min)."
        case let .ValueOutOfRangeBetween(varName, min, max):
            return "The value of `\(varName)` must be between \(min) and \(max)."
        case let .ValueOutOfRangeGe(varName, min):
            return "The value of `\(varName)` must be greater than or equal to \(min)."
        case .InvalidQuantity:
            return "Purchase quantity must be greater than 0."
        }
    }
}

public extension BluxError {
    struct ClientError: Error {
        public var message: String?
        public var httpStatusCode: Int?
    }
}

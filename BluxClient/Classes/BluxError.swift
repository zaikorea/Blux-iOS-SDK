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
        case .LengthOutOfRangeBetween(let varName, let min, let max):
            return "The length of `\(varName)` must be between \(min) and \(max)."
        case .LengthOutOfRangeGe(let varName, let min):
            return "The length of `\(varName)` must be greater than or equal to \(min)."
        case .ValueOutOfRangeBetween(let varName, let min, let max):
            return "The value of `\(varName)` must be between \(min) and \(max)."
        case .ValueOutOfRangeGe(let varName, let min):
            return "The value of `\(varName)` must be greater than or equal to \(min)."
        case .InvalidQuantity:
            return "Purchase quantity must be greater than 0."
        }
    }
}

extension BluxError {
    public struct ClientError: Error {
        public var message: String?
        public var httpStatusCode: Int?
    }
}


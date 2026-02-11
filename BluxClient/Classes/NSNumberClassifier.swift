import Foundation

enum NSNumberClassifier {
    enum Value {
        case bool(Bool)
        case int(Int)
        case double(Double)
    }

    static func classify(_ rawValue: Any) -> Value? {
        guard let numberValue = rawValue as? NSNumber else {
            return nil
        }

        if CFGetTypeID(numberValue) == CFBooleanGetTypeID() {
            return .bool(numberValue.boolValue)
        }

        if CFNumberIsFloatType(numberValue) {
            return .double(numberValue.doubleValue)
        }

        return .int(numberValue.intValue)
    }
}

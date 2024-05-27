import Foundation

public class Validator {
    static func validateString(_ value: String, min: Int, max: Int? = nil, varName: String) throws -> String {
        let length = value.count
        
        if let max = max {
            if length < min || length > max {
                throw BluxError.LengthOutOfRangeBetween(varName, min, max)
            }
        } else {
            if length < min {
                throw BluxError.LengthOutOfRangeGe(varName, min)
            }
        }
        
        return value
    }
    
    static func validateString(_ value: String?, min: Int, max: Int? = nil, varName: String) throws -> String? {
        guard let value = value else {
            return nil
        }
        
        let length = value.count
        
        if let max = max {
            if length < min || length > max {
                throw BluxError.LengthOutOfRangeBetween(varName, min, max)
            }
        } else {
            if length < min {
                throw BluxError.LengthOutOfRangeGe(varName, min)
            }
        }
        
        return value
    }
    
    static func validateNumber<T: Comparable>(_ value: T, min: T, max: T? = nil, varName: String) throws -> T {
        if let max = max {
            if value < min || value > max {
                throw BluxError.ValueOutOfRangeBetween(varName, min, max)
            }
        } else {
            if value < min {
                throw BluxError.ValueOutOfRangeGe(varName, min)
            }
        }
        
        return value
    }
}

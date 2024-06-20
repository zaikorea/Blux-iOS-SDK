//
//  Logger.swift
//  BluxClient
//
//  Created by Tommy on 5/21/24.
//

import Foundation

@objc public enum LogLevel: IntegerLiteralType, CustomStringConvertible {
    case none = 0
    case error = 1
    case verbose = 5
    
    public var description: String {
        switch self {
        case .none:
            return "none"
        case .error:
            return "error"
        case .verbose:
            return "verbose"
        }
    }
}

enum LogEvent: String {
    case error = "[ERROR]"
    case verbose = "[VERBOSE]"
}

public final class Logger {
    public static func error( _ object: Any, filename: String = #file, line: Int = #line, column: Int = #column, funcName: String = #function) {
        if SdkConfig.logLevel.rawValue >= LogLevel.error.rawValue {
            print("\(Date()) [BluxLogger]\(LogEvent.error.rawValue)[\(sourceFileName(filePath: filename))]:\(line) \(column) \(funcName) -> \(object)")
        }
    }
    
    public static func verbose( _ object: Any, filename: String = #file, line: Int = #line, column: Int = #column, funcName: String = #function) {
        if SdkConfig.logLevel.rawValue >= LogLevel.verbose.rawValue {
            print("\(Date()) [BluxLogger]\(LogEvent.verbose.rawValue)[\(sourceFileName(filePath: filename))]:\(line) \(column) \(funcName) -> \(object)")
        }
    }
    
    private static func sourceFileName(filePath: String) -> String {
        let components = filePath.components(separatedBy: "/")
        return components.isEmpty ? "" : components.last!
    }
}

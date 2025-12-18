//
//  Logger.swift
//  BluxClient
//
//  Created by Tommy on 5/21/24.
//

import Foundation
import os.log

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

public enum Logger {
    private static var osLog: OSLog {
        return OSLog(subsystem: Bundle.main.bundleIdentifier ?? "com.blux.client", category: "BluxLogger")
    }

    public static func error(_ object: Any, filename: String = #file, line: Int = #line, column: Int = #column, funcName: String = #function) {
        if SdkConfig.logLevel.rawValue >= LogLevel.error.rawValue {
            let message = "🔴 [BluxLogger]\(LogEvent.error.rawValue)[\(sourceFileName(filePath: filename))]:\(line) \(funcName) -> \(object)"
            os_log(.error, log: osLog, "%@", message)
        }
    }

    public static func verbose(_ object: Any, filename: String = #file, line: Int = #line, column: Int = #column, funcName: String = #function) {
        if SdkConfig.logLevel.rawValue >= LogLevel.verbose.rawValue {
            let message = "🔵 [BluxLogger]\(LogEvent.verbose.rawValue)[\(sourceFileName(filePath: filename))]:\(line) \(funcName) -> \(object)"
            os_log(.debug, log: osLog, "%@", message)
        }
    }

    private static func sourceFileName(filePath: String) -> String {
        let components = filePath.components(separatedBy: "/")
        return components.isEmpty ? "" : components.last!
    }
}

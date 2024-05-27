//
//  Utils.swift
//  BluxClient
//
//  Created by Tommy on 5/21/24.
//

import Foundation
import CryptoKit

final class Utils {
    static func getISO8601DateString() -> String {
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            return dateFormatter.string(from: Date())
        }

        static func getCurrentUnixTimestamp() -> Double {
            let time = DispatchTime.now().uptimeNanoseconds
            let milliseconds = Date().timeIntervalSince1970
            return milliseconds + Double(time % 1_000_000_000) / 1e9
        }

        static func sign(secret: String, message: String) -> String {
            let key = SymmetricKey(data: secret.data(using: .utf8)!)
            let signature = HMAC<SHA256>.authenticationCode(for: message.data(using: .utf8)!, using: key)
            return Data(signature).map { String(format: "%02hhx", $0) }.joined()
        }

        static func generateBluxToken(secret: String?, path: String, timestamp: String) -> String {
            guard let secret else {
                return ""
            }
            
            var modifiedPath = path
            if path.count > 1 && path.last == "/" {
                modifiedPath = String(path.dropLast())
            }
            let message = "\(modifiedPath):\(timestamp)"
            return sign(secret: secret, message: message)
        }
}

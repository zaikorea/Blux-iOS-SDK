//
//  Utils.swift
//  BluxClient
//
//  Created by Tommy on 5/21/24.
//

import Foundation
import CryptoKit

final class Utils {
    static func getCurrentUnixTimestamp() -> Double {
        let time = DispatchTime.now().uptimeNanoseconds
        let milliseconds = Date().timeIntervalSince1970
        return milliseconds + Double(time % 1_000_000_000) / 1e9
    }
}

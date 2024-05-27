import UIKit

final class Helper {
    
    // 앱이 포그라운드에 있는지 확인하는 메서드
    static func appInForeground() -> Bool {
        return UIApplication.shared.applicationState == .active
    }

    // 리소스 문자열을 가져오는 메서드
    static func getResourceString(identifier: String) -> String? {
        return Bundle.main.localizedString(forKey: identifier, value: nil, table: nil)
    }
}

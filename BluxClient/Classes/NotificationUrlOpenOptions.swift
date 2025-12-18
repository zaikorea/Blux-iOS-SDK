import Foundation

@objc public enum HttpUrlOpenTarget: Int {
    case internalWebView = 0
    case externalBrowser = 1
    case none = 2
}

@objcMembers
public final class NotificationUrlOpenOptions: NSObject {
    public let httpUrlOpenTarget: HttpUrlOpenTarget

    public init(httpUrlOpenTarget: HttpUrlOpenTarget = .internalWebView) {
        self.httpUrlOpenTarget = httpUrlOpenTarget
        super.init()
    }
}

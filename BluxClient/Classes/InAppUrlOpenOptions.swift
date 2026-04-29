import Foundation

@objcMembers
public final class InAppUrlOpenOptions: NSObject {
    public let httpUrlOpenTarget: HttpUrlOpenTarget

    public init(httpUrlOpenTarget: HttpUrlOpenTarget = .internalWebView) {
        self.httpUrlOpenTarget = httpUrlOpenTarget
        super.init()
    }
}

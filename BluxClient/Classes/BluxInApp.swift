import Foundation

@objc open class BluxInApp: NSObject {
    @objc public let id: String
    @objc public let url: String?

    @objc public init(id: String, url: String?) {
        self.id = id
        self.url = url == "" ? nil : url
        super.init()
    }
}

import Foundation

open class EventRequest {
    public var events: [Event] = []

    public func getPayload(isTest _: Bool = false) -> [Event] {
        return events
    }
}

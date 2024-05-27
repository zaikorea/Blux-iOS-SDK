import Foundation

open class EventRequest{
    public var events: [Event] = []
    
    public func getPayload(isTest: Bool = false) -> [Event] {
        return self.events
    }
}

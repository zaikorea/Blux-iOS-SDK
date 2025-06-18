import Foundation

public class AddPageVisitEvent: EventRequest {
    private static let DEFAULT_EVENT_TYPE: String = "page_visit"
    
    init(builder: Builder) throws {
        super.init()
        self.events.append(
            Event(eventType: builder.eventType)
                .setCustomEventProperties(builder.customEventProperties)
        )
    }
    
    public class Builder {
        fileprivate let eventType: String = DEFAULT_EVENT_TYPE
        
        fileprivate var customEventProperties: [String: CustomEventValue]? = nil
        
        public init() {}
        
        public func customEventProperties(_ customEventProperties: [String: CustomEventValue]) -> Builder {
            self.customEventProperties = customEventProperties
            return self
        }
        
        public func build() throws -> AddPageVisitEvent {
            return try AddPageVisitEvent(builder: self)
        }
    }
}

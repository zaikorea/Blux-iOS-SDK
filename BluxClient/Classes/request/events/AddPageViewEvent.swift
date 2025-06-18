import Foundation

public class AddPageViewEvent: EventRequest {
    private static let DEFAULT_EVENT_TYPE: String = "page_view"
    
    init(builder: Builder) throws {
        super.init()
        try self.events.append(
            Event(eventType: builder.eventType)
                .setPage(builder.page)
                .setCustomEventProperties(builder.customEventProperties)
        )
    }
    
    public class Builder {
        fileprivate let eventType: String = DEFAULT_EVENT_TYPE
        fileprivate let page: String
        
        fileprivate var customEventProperties: [String: CustomEventValue]? = nil
        
        public init(page: String) {
            self.page = page
        }
        
        public func customEventProperties(_ customEventProperties: [String: CustomEventValue]) -> Builder {
            self.customEventProperties = customEventProperties
            return self
        }
        
        public func build() throws -> AddPageViewEvent {
            return try AddPageViewEvent(builder: self)
        }
    }
}

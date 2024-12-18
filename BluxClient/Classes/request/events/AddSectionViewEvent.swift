import Foundation

public class AddSectionViewEvent: EventRequest {
    private static let DEFAULT_EVENT_TYPE: String = "section_view"
    
    init(builder: Builder) throws {
        super.init()
        try self.events.append(
            Event(eventType: builder.eventType)
                .setSection(builder.section)
                .setRecommendationId(builder.recommendationId)
                .setCustomEventProperties(builder.customEventProperties)
        )
    }
    
    public class Builder {
        fileprivate let eventType: String = DEFAULT_EVENT_TYPE
        fileprivate let section: String
        
        fileprivate var recommendationId: String? = nil
        fileprivate var customEventProperties: [String: String]? = nil
        
        public init(section: String) {
            self.section = section
        }
        
        public func recommendationId(_ recommendationId: String) -> Builder {
            self.recommendationId = recommendationId
            return self
        }
        
        public func customEventProperties(_ customEventProperties: [String: String]) -> Builder {
            self.customEventProperties = customEventProperties
            return self
        }
        
        public func build() throws -> AddSectionViewEvent {
            return try AddSectionViewEvent(builder: self)
        }
    }
}

import Foundation

public class AddProductDetailViewEvent: EventRequest {
    private static let DEFAULT_EVENT_TYPE: String = "product_detail_view"
    
    init(builder: Builder) throws {
        super.init()
        try self.events.append(
            Event(eventType: builder.eventType)
                .setItemId(builder.itemId)
                .setPrevPage(builder.prevPage)
                .setPrevSection(builder.prevSection)
                .setRecommendationId(builder.recommendationId)
                .setCustomEventProperties(builder.customEventProperties)
        )
    }
    
    public class Builder {
        fileprivate let eventType: String = AddProductDetailViewEvent.DEFAULT_EVENT_TYPE
        fileprivate let itemId: String
        
        fileprivate var prevPage: String? = nil
        fileprivate var prevSection: String? = nil
        fileprivate var recommendationId: String? = nil
        fileprivate var customEventProperties: [String: String]? = nil
        
        public init(itemId: String) {
            self.itemId = itemId
        }
        
        public func prevPage(_ prevPage: String) -> Builder {
            self.prevPage = prevPage
            return self
        }
        
        public func prevSection(_ prevSection: String) -> Builder {
            self.prevSection = prevSection
            return self
        }
        
        public func recommendationId(_ recommendationId: String) -> Builder {
            self.recommendationId = recommendationId
            return self
        }
        
        public func customEventProperties(_ customEventProperties: [String: String]) -> Builder {
            self.customEventProperties = customEventProperties
            return self
        }
        
        public func build() throws -> AddProductDetailViewEvent {
            return try AddProductDetailViewEvent(builder: self)
        }
    }
}

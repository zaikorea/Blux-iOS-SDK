import Foundation

public class AddPersistentImpressionEvent: EventRequest {
    private static let DEFAULT_EVENT_TYPE = "persistent_impression"

    init(builder: Builder) throws {
        super.init()
        try self.events.append(
            Event(eventType: builder.eventType)
                .setItemId(builder.itemId)
                .setPage(builder.page)
                .setSection(builder.section)
                .setPosition(builder.position)
                .setRecommendationId(builder.recommendationId ?? "")
                .setCustomEventProperties(builder.customEventProperties ?? [:])
        )
    }

    public class Builder {
        fileprivate let eventType: String = DEFAULT_EVENT_TYPE
        fileprivate let itemId: String
        fileprivate let page: String
        fileprivate let section: String
        fileprivate let position: Double

        fileprivate var recommendationId: String? = nil
        fileprivate var customEventProperties: [String: String]? = nil

        public init(itemId: String, page: String, section: String, position: Double) {
            self.itemId = itemId
            self.page = page
            self.section = section
            self.position = position
        }

        public func recommendationId(_ recommendationId: String) -> Builder {
            self.recommendationId = recommendationId
            return self
        }

        public func customEventProperties(_ customEventProperties: [String: String]) -> Builder {
            self.customEventProperties = customEventProperties
            return self
        }

        public func build() throws -> AddPersistentImpressionEvent {
            return try AddPersistentImpressionEvent(builder: self)
        }
    }
}

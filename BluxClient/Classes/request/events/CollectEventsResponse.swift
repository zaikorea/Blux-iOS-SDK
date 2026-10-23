import Foundation

/// 인앱 응답 페이로드 - inapp 객체가 있으면 표시, 없으면 표시 안 함
struct InappDispatchResponse: Codable {
    let notificationId: String
    let htmlString: String
    let inappId: String
    let baseUrl: String

    enum CodingKeys: String, CodingKey {
        case notificationId
        case htmlString
        case inappId
        case baseUrl
    }
}

/// collect-events 응답 모델: 다음 폴링 지연(ms)과 인앱 페이로드를 함께 전달
struct CollectEventsResponse: Codable {
    let nextPollDelayMs: Int?
    let inapp: InappDispatchResponse?

    enum CodingKeys: String, CodingKey {
        case nextPollDelayMs
        case inapp
    }
}


import Foundation

enum InappDispatchResponse: Codable {
    case display(notificationId: String, htmlString: String, inappId: String, baseUrl: String)
    case noDisplay

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let shouldDisplay = try container.decode(Bool.self, forKey: .shouldDisplay)

        if shouldDisplay {
            let notificationId = try container.decode(String.self, forKey: .notificationId)
            let htmlString = try container.decode(String.self, forKey: .htmlString)
            let inappId = try container.decode(String.self, forKey: .inappId)
            let baseUrl = try container.decode(String.self, forKey: .baseUrl)

            self = .display(
                notificationId: notificationId,
                htmlString: htmlString,
                inappId: inappId,
                baseUrl: baseUrl
            )
        } else {
            self = .noDisplay
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .display(let notificationId, let htmlString, let inappId, let baseUrl):
            try container.encode(true, forKey: .shouldDisplay)
            try container.encode(notificationId, forKey: .notificationId)
            try container.encode(htmlString, forKey: .htmlString)
            try container.encode(inappId, forKey: .inappId)
            try container.encode(baseUrl, forKey: .baseUrl)
        case .noDisplay:
            try container.encode(false, forKey: .shouldDisplay)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case notificationId
        case htmlString
        case shouldDisplay
        case inappId
        case baseUrl
    }
}

struct InappDispatchRequest: Codable {
    let bluxUserId: String
    let deviceId: String
    let platform: String = "ios"

    public init(bluxUserId: String, deviceId: String) {
        self.bluxUserId = bluxUserId
        self.deviceId = deviceId
    }

    enum CodingKeys: String, CodingKey {
        case bluxUserId = "blux_user_id"
        case deviceId = "device_id"
        case platform
    }
}

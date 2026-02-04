import Foundation

enum Stage: String, CaseIterable {
    case local = "local"
    case dev = "dev"
    case stg = "stg"
    case prod = "prod"

    static func from(_ value: String?) -> Stage {
        guard let value else {
            Logger.error("Stage.from: value is nil, falling back to PROD")
            return .prod
        }

        if let stage = Self.allCases.first(where: { $0.rawValue.caseInsensitiveCompare(value) == .orderedSame }) {
            return stage
        }

        Logger.error("Stage.from: Unknown value '\(value)', falling back to PROD")
        return .prod
    }

    static var defaultForBuild: Stage {
#if BLUX_LOCAL
        return .local
#elseif BLUX_DEV
        return .dev
#elseif BLUX_STG
        return .stg
#else
        return .prod
#endif
    }

    static var current: Stage { defaultForBuild }

    var apiBaseURL: HTTPClient.APIBaseURLByStage {
        switch self {
        case .local: return .local
        case .dev: return .dev
        case .stg: return .stg
        case .prod: return .prod
        }
    }
}

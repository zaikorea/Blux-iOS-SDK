import Foundation

public enum Stage: String, CaseIterable {
    case local
    case dev
    case stg
    case prod

    public static func from(_ value: String?) -> Stage {
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

    /// 1. Info.plist의 "BluxStage" 값 확인
    /// 2. 없으면 컴파일 플래그 확인 (BLUX_LOCAL, BLUX_DEV, BLUX_STG)
    /// 3. 기본값 prod
    public static var current: Stage = {
        // Info.plist에서 먼저 확인
        if let stageString = Bundle.main.object(forInfoDictionaryKey: "BluxStage") as? String,
           !stageString.isEmpty
        {
            return Stage.from(stageString)
        }
        // 컴파일 플래그 확인
        #if BLUX_LOCAL
            return .local
        #elseif BLUX_DEV
            return .dev
        #elseif BLUX_STG
            return .stg
        #else
            return .prod
        #endif
    }()

    var apiBaseURL: HTTPClient.APIBaseURLByStage {
        switch self {
        case .local: return .local
        case .dev: return .dev
        case .stg: return .stg
        case .prod: return .prod
        }
    }
}

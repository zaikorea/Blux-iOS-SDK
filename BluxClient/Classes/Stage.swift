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

    // MARK: - Stage Management

    /// 빌드 시점의 기본 스테이지
    /// 1. Info.plist의 "BluxStage" 값 확인
    /// 2. 없으면 컴파일 플래그 확인 (BLUX_LOCAL, BLUX_DEV, BLUX_STG)
    /// 3. 기본값 prod
    private static let defaultStage: Stage = {
        if let stageString = Bundle.main.object(forInfoDictionaryKey: "BluxStage") as? String,
           !stageString.isEmpty
        {
            return Stage.from(stageString)
        }
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

    /// 런타임 오버라이드 (stage 전환은 극히 드문 UI 액션이므로 별도 동기화 불필요)
    private static var overrideStage: Stage?

    /// 현재 스테이지 (오버라이드가 있으면 오버라이드, 없으면 빌드 시점 기본값)
    public static var current: Stage {
        overrideStage ?? defaultStage
    }

    // MARK: - Stage Switching (internal only)

    #if ENABLE_STAGE_SWITCHING
        /// 런타임에 스테이지를 변경합니다.
        /// ENABLE_STAGE_SWITCHING 플래그가 설정된 빌드(local/dev/stg)에서만 동작합니다.
        @discardableResult
        static func setStage(_ stage: Stage) -> Bool {
            overrideStage = stage
            HTTPClient.shared.setStage(stage)
            return true
        }

        /// 런타임에 변경된 스테이지를 빌드 시점의 스테이지로 되돌립니다.
        static func resetStage() {
            overrideStage = nil
            HTTPClient.shared.setStage(defaultStage)
        }
    #endif

    var apiBaseURL: HTTPClient.APIBaseURLByStage {
        switch self {
        case .local: return .local
        case .dev: return .dev
        case .stg: return .stg
        case .prod: return .prod
        }
    }
}

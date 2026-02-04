import Foundation

enum Credentials {
    // applicationId는 기밀이 아니므로 커밋합니다.
    static let applicationId = "66fac6b03e71e06835703c25"

    static var apiKey: String {
        (Bundle.main.object(forInfoDictionaryKey: "BluxAPIKey") as? String) ?? ""
    }

    static var sdkStage: String {
        (Bundle.main.object(forInfoDictionaryKey: "BluxSDKStage") as? String) ?? "prod"
    }
}

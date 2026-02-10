import BluxClient
import Foundation

enum Credentials {
    static func getApplicationId(stage: Stage) -> String {
        switch stage {
        case .local, .dev, .stg:
            return "69327634beb1da48e4278ed6"
        case .prod:
            return "6932742fb4bedc9b2239055a"
        }
    }

    /// stage별 API key (Info.plist에서 BluxAPIKey{Stage} 키로 읽음)
    static func getApiKey(stage: Stage) -> String {
        let key: String
        switch stage {
        case .local: key = "BluxAPIKeyLocal"
        case .dev:   key = "BluxAPIKeyDev"
        case .stg:   key = "BluxAPIKeyStg"
        case .prod:  key = "BluxAPIKeyProd"
        }
        return (Bundle.main.object(forInfoDictionaryKey: key) as? String) ?? ""
    }
}

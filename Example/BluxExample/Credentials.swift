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

    static var apiKey: String {
        (Bundle.main.object(forInfoDictionaryKey: "BluxAPIKey") as? String) ?? ""
    }
}

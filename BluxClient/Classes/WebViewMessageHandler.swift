typealias JSON = [String: Any]

final class WebViewMessageHandler {
    private var handlers: [String: (JSON) -> Void] = [:]

    func registerHandler(for action: String, handler: @escaping (JSON) -> Void) {
        handlers[action] = handler
    }

    func unregisterHandler(for action: String) {
        handlers.removeValue(forKey: action)
    }

    func handleMessage(_ action: String, data: JSON) {
        if let handler = handlers[action] {
            handler(data)
        } else {
            Logger.verbose("No handler found for action: \(action)")
        }
    }
}

//
//  BluxWebSdkBridge.swift
//  BluxClient
//
//  Web SDK(iOS WKWebView) -> iOS SDK 브릿지
//
//  Web SDK는 window.webkit.messageHandlers.Blux.postMessage(JSON.stringify({ action, payload }))
//  형태로 호출합니다.
//

import Foundation
import WebKit

/// iOS 앱의 WKWebView에서 Blux Web SDK를 사용할 때 필요한 브릿지입니다.
///
/// ## iOS 설정
/// ```swift
/// let webView = WKWebView()
/// BluxWebSdkBridge.attach(to: webView)
/// ```
///
/// ## Web SDK 설정
/// ```typescript
/// const bluxClient = new BluxClient({
///     bluxApplicationId: 'your-application-id',
///     bluxAPIKey: 'your-api-key',
///     bridgePlatform: 'ios'
/// });
/// ```
@available(iOSApplicationExtension, unavailable)
public final class BluxWebSdkBridge: NSObject {
    public static let handlerName = "Blux"

    @discardableResult
    public static func attach(to webView: WKWebView) -> BluxWebSdkBridge {
        let bridge = BluxWebSdkBridge()
        webView.configuration.userContentController.add(bridge, name: handlerName)
        Logger.verbose("BluxWebSdkBridge attached")
        return bridge
    }

    public static func detach(from webView: WKWebView) {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: handlerName)
        Logger.verbose("BluxWebSdkBridge detached")
    }
}

// MARK: - WKScriptMessageHandler

@available(iOSApplicationExtension, unavailable)
extension BluxWebSdkBridge: WKScriptMessageHandler {
    public func userContentController(_: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == BluxWebSdkBridge.handlerName else { return }
        handle(scriptMessageBody: message.body)
    }

    func handle(scriptMessageBody body: Any) {
        let json: [String: Any]?
        if let str = body as? String,
           let data = str.data(using: .utf8),
           let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        {
            json = obj
        } else if let obj = body as? [String: Any] {
            json = obj
        } else {
            Logger.error("BluxWebSdkBridge: invalid message format")
            return
        }

        guard let json,
              let action = json["action"] as? String, !action.isEmpty
        else {
            Logger.error("BluxWebSdkBridge: missing action")
            return
        }

        handleAction(action, payload: json["payload"])
    }
}

// MARK: - Action Handlers

@available(iOSApplicationExtension, unavailable)
private extension BluxWebSdkBridge {
    func handleAction(_ action: String, payload: Any?) {
        switch action {
        case "initialize":
            handleInitialize(payload)
        case "signIn":
            handleSignIn(payload)
        case "signOut":
            BluxClient.signOut()
        case "setUserProperties":
            handleSetUserProperties(payload)
        case "setCustomUserProperties":
            handleSetCustomUserProperties(payload)
        case "sendEvent":
            handleSendEvent(payload)
        default:
            Logger.error("BluxWebSdkBridge: unknown action=\(action)")
        }
    }

    func handleInitialize(_ payload: Any?) {
        guard let dict = payload as? [String: Any],
              let appId = dict["bluxApplicationId"] as? String, !appId.isEmpty,
              let apiKey = dict["bluxAPIKey"] as? String, !apiKey.isEmpty
        else {
            Logger.error("BluxWebSdkBridge.initialize: missing credentials")
            return
        }

        let requestPermission = (dict["requestPermissionOnLaunch"] as? Bool) ?? true
        BluxClient.initialize(nil, bluxApplicationId: appId, bluxAPIKey: apiKey, requestPermissionOnLaunch: requestPermission)
    }

    func handleSignIn(_ payload: Any?) {
        guard let dict = payload as? [String: Any],
              let userId = dict["userId"] as? String, !userId.isEmpty
        else {
            Logger.error("BluxWebSdkBridge.signIn: missing userId")
            return
        }
        BluxClient.signIn(userId: userId)
    }

    func handleSetUserProperties(_ payload: Any?) {
        guard let dict = payload as? [String: Any] else {
            Logger.error("BluxWebSdkBridge.setUserProperties: invalid payload")
            return
        }

        do {
            let data = try JSONSerialization.data(withJSONObject: dict)
            let userProperties = try JSONDecoder().decode(UserProperties.self, from: data)
            BluxClient.setUserProperties(userProperties: userProperties)
        } catch {
            Logger.error("BluxWebSdkBridge.setUserProperties: \(error)")
        }
    }

    func handleSetCustomUserProperties(_ payload: Any?) {
        guard let dict = payload as? [String: Any] else {
            Logger.error("BluxWebSdkBridge.setCustomUserProperties: invalid payload")
            return
        }

        var sanitized: [String: Any?] = [:]
        for (key, value) in dict {
            if value is NSNull {
                sanitized[key] = nil
            } else {
                sanitized[key] = value
            }
        }

        BluxClient.setCustomUserProperties(customUserProperties: sanitized)
    }

    func handleSendEvent(_ payload: Any?) {
        guard let dict = payload as? [String: Any],
              let requests = dict["requests"] as? [[String: Any]], !requests.isEmpty
        else {
            return
        }

        let events = requests.compactMap { buildEvent(from: $0) }
        if !events.isEmpty {
            BluxClient.sendRequestData(events)
        }
    }

    func buildEvent(from dict: [String: Any]) -> Event? {
        guard let eventType = dict["event_type"] as? String, !eventType.isEmpty else {
            return nil
        }

        let event = Event(eventType: eventType)

        if let capturedAt = dict["captured_at"] as? String, !capturedAt.isEmpty {
            event.capturedAt = capturedAt
        }

        if let propsDict = dict["event_properties"] as? [String: Any] {
            if let props: EventProperties = decode(propsDict) {
                event.setEventProperties(props)
            }
        }

        if let customDict = dict["custom_event_properties"] as? [String: Any] {
            event.setCustomEventProperties(CustomEventValue.dictionaryFromAny(customDict))
        }

        if let internalDict = dict["internal_event_properties"] as? [String: Any] {
            event.setInternalEventProperties(CustomEventValue.dictionaryFromAny(internalDict))
        }

        return event
    }

    func decode<T: Decodable>(_ dict: [String: Any]) -> T? {
        guard let data = try? JSONSerialization.data(withJSONObject: dict) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}

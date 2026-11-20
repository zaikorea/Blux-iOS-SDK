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
        let controller = webView.configuration.userContentController
        if #available(iOS 14.0, *) {
            // 응답 가능한 핸들러로 등록해야 Web SDK의 getBluxUser가 값을 받는다.
            controller.addScriptMessageHandler(bridge, contentWorld: .page, name: handlerName)
        } else {
            controller.add(bridge, name: handlerName)
        }
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

    /// 메시지를 처리하고 Web SDK에 돌려줄 응답을 반환한다. `getBluxUser` action에만 값이 있다.
    @discardableResult
    func handle(scriptMessageBody body: Any) -> Any? {
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
            return nil
        }

        guard let json,
              let action = json["action"] as? String, !action.isEmpty
        else {
            Logger.error("BluxWebSdkBridge: missing action")
            return nil
        }

        return handleAction(action, payload: json["payload"])
    }
}

// MARK: - WKScriptMessageHandlerWithReply

@available(iOS 14.0, *)
@available(iOSApplicationExtension, unavailable)
extension BluxWebSdkBridge: WKScriptMessageHandlerWithReply {
    /// 웹의 `postMessage`가 반환한 Promise는 `replyHandler`를 불러야 끝나므로, 모든 메시지에 한 번씩 응답한다.
    public func userContentController(
        _: WKUserContentController,
        didReceive message: WKScriptMessage,
        replyHandler: @escaping (Any?, String?) -> Void
    ) {
        guard message.name == BluxWebSdkBridge.handlerName else {
            replyHandler(nil, nil)
            return
        }
        replyHandler(handle(scriptMessageBody: message.body), nil)
    }
}

// MARK: - Action Handlers

@available(iOSApplicationExtension, unavailable)
private extension BluxWebSdkBridge {
    func handleAction(_ action: String, payload: Any?) -> Any? {
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
        case "pageTransition":
            BluxClient.notifyPageTransition()
        case "getBluxUser":
            return bluxUserPayload()
        default:
            Logger.error("BluxWebSdkBridge: unknown action=\(action)")
        }
        return nil
    }

    /// Web SDK의 `bluxUserPayloadSchema`와 같은 모양이다. 둘 중 하나라도 없으면 `nil`이다.
    func bluxUserPayload() -> [String: String]? {
        guard let id = BluxUser.getId(), let deviceId = BluxUser.getDeviceId() else { return nil }
        return ["bluxUserId": id, "deviceId": deviceId]
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
        let customDeviceId = dict["customDeviceId"] as? String
        BluxClient.initialize(
            nil,
            bluxApplicationId: appId,
            bluxAPIKey: apiKey,
            requestPermissionOnLaunch: requestPermission,
            customDeviceId: customDeviceId
        )
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

        BluxClient.setUserPropertiesData(userProperties: dict)
    }

    func handleSetCustomUserProperties(_ payload: Any?) {
        guard let dict = payload as? [String: Any] else {
            Logger.error("BluxWebSdkBridge.setCustomUserProperties: invalid payload")
            return
        }

        BluxClient.setCustomUserProperties(customUserProperties: dict)
    }

    func handleSendEvent(_ payload: Any?) {
        guard let dict = payload as? [String: Any],
              let requests = dict["requests"] as? [[String: Any]], !requests.isEmpty
        else {
            return
        }

        let events = buildEvents(from: requests)
        if !events.isEmpty {
            BluxClient.sendRequestData(events)
        }
    }

    func buildEvent(from dict: [String: Any], requestIndex: Int) -> Event? {
        guard let eventType = dict["event_type"] as? String, !eventType.isEmpty else {
            return nil
        }

        let event = Event(eventType: eventType)

        if let capturedAt = dict["captured_at"] as? String, !capturedAt.isEmpty {
            event.capturedAt = capturedAt
        }

        if let rawProperties = dict["event_properties"] {
            guard let propsDict = rawProperties as? [String: Any],
                  let data = try? JSONSerialization.data(withJSONObject: propsDict),
                  let props = try? JSONDecoder().decode(EventProperties.self, from: data)
            else {
                logInvalidEventProperties(index: requestIndex, eventType: eventType)
                return nil
            }

            event.setEventProperties(props)
        }

        if let customDict = dict["custom_event_properties"] as? [String: Any] {
            event.setCustomEventProperties(CustomEventValue.dictionaryFromAny(customDict))
        }

        if let internalDict = dict["internal_event_properties"] as? [String: Any] {
            event.setInternalEventProperties(CustomEventValue.dictionaryFromAny(internalDict))
        }

        return event
    }

    func logInvalidEventProperties(index: Int, eventType: String) {
        Logger.error(
            "BluxWebSdkBridge.sendEvent: invalid event_properties"
                + " index=\(index) event_type=\(eventType)"
        )
    }
}

@available(iOSApplicationExtension, unavailable)
extension BluxWebSdkBridge {
    func buildEvents(from requests: [[String: Any]]) -> [Event] {
        requests.enumerated().compactMap { index, request in
            buildEvent(from: request, requestIndex: index)
        }
    }
}

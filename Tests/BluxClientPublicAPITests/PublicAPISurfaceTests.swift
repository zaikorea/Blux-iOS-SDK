import XCTest
import UIKit
import WebKit
import BluxClient

/// wrapper SDK(RN/Flutter)가 import하는 것과 동일한 plain `import BluxClient`로 작성.
/// public→internal 강등 같은 access-control 회귀가 BluxClientTests(@testable)를 통과하더라도
/// 이 타겟은 컴파일 실패해 회귀를 잡는다.
///
/// 모든 검증은 컴파일 시점. method/type reference로 시그니처를 잡으면 되며 실제 호출은 불필요.
final class PublicAPISurfaceTests: XCTestCase {
    func testBluxClientPublicMethodSignaturesCompile() {
        let _: ([UIApplication.LaunchOptionsKey: Any]?, String, String, Bool, String?, @escaping ((NSError?) -> Void)) -> Void
            = BluxClient.initialize(_:bluxApplicationId:bluxAPIKey:requestPermissionOnLaunch:customDeviceId:completion:)

        let _: (LogLevel) -> Void = BluxClient.setLogLevel(level:)

        let _: (String, @escaping ((NSError?) -> Void)) -> Void = BluxClient.signIn(userId:completion:)

        let _: () -> Void = BluxClient.signOut

        let _: ([String: Any?]) -> Void = BluxClient.setUserPropertiesData(userProperties:)

        let _: (UserProperties) -> Void = BluxClient.setUserProperties(userProperties:)

        let _: ([String: Any?]) -> Void = BluxClient.setCustomUserProperties(customUserProperties:)

        let _: ([Event]) -> Void = BluxClient.sendRequestData

        let _: (EventRequest) -> Void = BluxClient.sendEvent

        let _: (NotificationUrlOpenOptions) -> Void = BluxClient.setNotificationUrlOpenOptions

        let _: (InAppUrlOpenOptions) -> Void = BluxClient.setInAppUrlOpenOptions

        let _: () -> Void = BluxClient.dismissInApp

        let _: (@escaping (BluxNotification) -> Void) -> Void = BluxClient.setNotificationClickedHandler(callback:)

        let _: (@escaping (BluxInApp) -> Void) -> Void = BluxClient.setInAppClickedHandler(callback:)

        let _: (@escaping (NotificationReceivedEvent) -> Void) -> Void
            = BluxClient.setNotificationForegroundWillDisplayHandler(callback:)

        let _: (@escaping (String, [String: Any]) -> Void) -> () -> Void
            = BluxClient.addInAppCustomActionHandler(callback:)
    }

    func testPublicTypeMembersCompile() {
        // Event public init과 mutable capturedAt
        let event = Event(eventType: "x")
        event.capturedAt = "2025-01-01T00:00:00.000Z"

        // Event 체인 메서드는 public
        let _: (EventProperties?) -> Event = event.setEventProperties
        let _: ([String: CustomEventValue]?) -> Event = event.setCustomEventProperties
        let _: ([String: CustomEventValue]?) -> Event = event.setInternalEventProperties

        // EventProperties는 wrapper SDK에서 JSONDecoder로만 생성하므로 직접 init() 검증은 하지 않는다.
        // (현재 EventProperties는 명시적 public init이 없어 wrapper 모듈에서 직접 init 불가.
        //  Codable witness를 통한 디코딩만 가능.)
        let _ = try? JSONDecoder().decode(EventProperties.self, from: Data("{}".utf8))

        // UserProperties는 public init으로 wrapper SDK가 직접 생성한다 (Flutter 패턴).
        let _ = UserProperties()
        let _ = UserProperties(phoneNumber: "x")
        let _ = UserProperties(age: 1)
        let _ = UserProperties(gender: .male)

        // CustomEventValue.fromAny public
        let _: CustomEventValue? = CustomEventValue.fromAny("x")

        // BluxNotification public init
        let _ = BluxNotification(id: "x", body: "y", title: nil, url: nil, imageUrl: nil, data: nil)

        // BluxInApp public init
        let _ = BluxInApp(id: "x", url: "https://example.com")

        // LogLevel cases
        let _: LogLevel = .verbose
        let _: LogLevel = .error
        let _: LogLevel = .none
    }

    func testHttpUrlOpenTargetMembersAccessible() {
        let _: HttpUrlOpenTarget = .internalWebView
        let _: HttpUrlOpenTarget = .externalBrowser
        let _: HttpUrlOpenTarget = HttpUrlOpenTarget.none
    }

    func testBluxWebSdkBridgePublicSignaturesCompile() {
        // wrapper SDK에서 import해 호출하므로 시그니처는 public으로 유지돼야 한다.
        // WKWebView 인스턴스화는 시뮬레이터 GPU 초기화를 트리거해 후속 테스트를 stall시키므로
        // 메서드 참조만 잡아 컴파일 타임에 시그니처를 락-인한다 (실제 호출은 안 함).
        let _: String = BluxWebSdkBridge.handlerName
        let _: (WKWebView) -> BluxWebSdkBridge = BluxWebSdkBridge.attach(to:)
        let _: (WKWebView) -> Void = BluxWebSdkBridge.detach(from:)
    }

    func testStageSwitcherIsAccessibleViaObjCRuntime() {
        // RN/Flutter SDK는 StageSwitcher를 NSClassFromString("BluxStageSwitcher")로 호출 가능해야 함.
        // (`@objc(BluxStageSwitcher)` runtime 노출 검증)
        let cls: AnyClass? = NSClassFromString("BluxStageSwitcher")
        XCTAssertNotNil(cls)
    }
}

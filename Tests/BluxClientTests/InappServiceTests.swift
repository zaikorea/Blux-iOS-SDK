import XCTest
import UIKit
@testable import BluxClient

final class InappServiceTests: XCTestCase {
    override func setUp() {
        super.setUp()
        InappService.notifyPageTransition()
    }

    func testPendingOnlyBlocksTheSameGenerationAndCanBeReleased() {
        let page = InappService.currentPageTransitionCount
        let response = InappDispatchResponse(
            notificationId: "n", htmlString: "", inappId: "pending", baseUrl: "",
            displayDelaySeconds: 1
        )
        XCTAssertTrue(InappService.beginDelayedInapp("pending", pageTransitionCount: page))
        XCTAssertFalse(InappService.beginDelayedInapp("pending", pageTransitionCount: page))
        InappService.notifyPageTransition()
        let next = InappService.currentPageTransitionCount
        XCTAssertTrue(InappService.beginDelayedInapp("pending", pageTransitionCount: next))
        InappService.finishDelayedInapp(response, pageTransitionCount: page)
        XCTAssertFalse(InappService.beginDelayedInapp("pending", pageTransitionCount: next))
        InappService.finishDelayedInapp(response, pageTransitionCount: next)
        XCTAssertTrue(InappService.beginDelayedInapp("pending", pageTransitionCount: next))
        InappService.finishDelayedInapp(response, pageTransitionCount: next)
        XCTAssertFalse(InappService.beginDelayedInapp("pending", pageTransitionCount: page))
    }

    func testImmediateResponseDoesNotReleaseThePendingDelayWithTheSameId() {
        let page = InappService.currentPageTransitionCount
        XCTAssertTrue(InappService.beginDelayedInapp("mixed", pageTransitionCount: page))
        let response = InappDispatchResponse(
            notificationId: "n", htmlString: "", inappId: "mixed", baseUrl: "",
            displayDelaySeconds: 0
        )
        InappService.finishDelayedInapp(response, pageTransitionCount: page)
        XCTAssertFalse(InappService.beginDelayedInapp("mixed", pageTransitionCount: page))
    }

    func testInactiveDropReleasesTheDelayForAnotherTriggerOnTheSamePage() {
        InappService.startMonitoringState()
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        defer { NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil) }
        let page = InappService.currentPageTransitionCount
        let response = InappDispatchResponse(
            notificationId: "n", htmlString: "", inappId: "inactive", baseUrl: "https://inapp.blux.ai",
            displayDelaySeconds: 1
        )
        InappService.handleInappResponse(response, pageTransitionCount: page)
        XCTAssertFalse(InappService.beginDelayedInapp("inactive", pageTransitionCount: page))
        let drained = expectation(description: "inactive response is discarded")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            XCTAssertTrue(InappService.beginDelayedInapp("inactive", pageTransitionCount: page))
            InappService.finishDelayedInapp(response, pageTransitionCount: page)
            drained.fulfill()
        }
        wait(for: [drained], timeout: 3)
    }

    func testDelayedResponseReturnsWithoutHoldingTheEventCompletion() {
        let response = InappDispatchResponse(
            notificationId: "n", htmlString: "", inappId: "delay-test", baseUrl: "",
            displayDelaySeconds: 1
        )
        let returned = expectation(description: "event completion continues before delay")
        DispatchQueue.main.async {
            InappService.handleInappResponse(response, pageTransitionCount: InappService.currentPageTransitionCount)
            returned.fulfill()
        }
        wait(for: [returned], timeout: 0.5)
        // 예약된 작업을 끝내 다음 테스트로 유출하지 않는다.
        let drained = expectation(description: "delay drained")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) { drained.fulfill() }
        wait(for: [drained], timeout: 2)
    }

    func testReplacingBluxIdInvalidatesOnlyAnExistingDifferentIdentity() {
        let state = SdkStateGuard()
        defer { state.restore() }
        SdkConfig.bluxIdInUserDefaults = nil
        let before = InappService.currentPageTransitionCount
        DeviceService.replaceBluxId("A")
        DeviceService.replaceBluxId("A")
        XCTAssertEqual(InappService.currentPageTransitionCount, before)
        DeviceService.replaceBluxId("B")
        XCTAssertEqual(SdkConfig.bluxIdInUserDefaults, "B")
        XCTAssertEqual(InappService.currentPageTransitionCount, before + 1)
    }
    // 표시 중인 인앱이 없는 baseline에서도 cleanup 함수들이 안전 호출되어야 한다.
    // signOut / credential 전환 경로에서 무조건 호출되므로 회귀 시 signOut 자체가 깨진다.
    func testCleanupIsSafeWhenNothingShown() {
        InappService.dismissCurrentInApp()
        InappService.clearInappQueue()
    }

    // handleInappResponse가 백그라운드 스레드에서 호출돼도 main으로 dispatch되어
    // webViewQueue 조작이 안전해야 한다. (회귀: race condition으로 "Index out of range" 크래시)
    func testHandleInappResponseSafeFromBackgroundThread() {
        let response = InappDispatchResponse(
            notificationId: "n",
            htmlString: "<html></html>",
            inappId: "i",
            baseUrl: "https://cdn.blux.ai"
        )

        let exp = expectation(description: "no crash from background dispatch")
        DispatchQueue.global().async {
            InappService.handleInappResponse(response, pageTransitionCount: 0)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 2.0)

        let drain = expectation(description: "main drain")
        DispatchQueue.main.async {
            InappService.clearInappQueue()
            InappService.dismissCurrentInApp()
            drain.fulfill()
        }
        wait(for: [drain], timeout: 2.0)
    }

    func testHandleInappResponseRejectsInvalidBaseURL() {
        let response = InappDispatchResponse(
            notificationId: "n",
            htmlString: "<html></html>",
            inappId: "i",
            baseUrl: ""
        )
        InappService.handleInappResponse(response, pageTransitionCount: 0)
    }

    // notifyPageTransition은 번호를 호출 스레드에서 바로 올린다. SDK 초기화 여부와 무관하다.
    func testNotifyPageTransitionIncrementsCount() {
        let before = InappService.currentPageTransitionCount
        InappService.notifyPageTransition()
        XCTAssertEqual(InappService.currentPageTransitionCount, before + 1)
    }
}

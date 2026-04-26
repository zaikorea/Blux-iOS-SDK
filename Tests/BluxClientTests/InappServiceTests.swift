import XCTest
@testable import BluxClient

final class InappServiceTests: XCTestCase {
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
            InappService.handleInappResponse(response)
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
        InappService.handleInappResponse(response)
    }
}

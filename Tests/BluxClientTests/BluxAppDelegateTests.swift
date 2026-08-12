import XCTest
@testable import BluxClient

final class BluxAppDelegateTests: XCTestCase {
    func testApnsDeviceTokenIsConvertedToPushTokenString() {
        let deviceToken = Data([0x00, 0x0A, 0x7F, 0xFF])

        XCTAssertEqual(BluxAppDelegate.pushTokenString(from: deviceToken), "000a7fff")
    }
}

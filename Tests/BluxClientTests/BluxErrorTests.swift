import XCTest
@testable import BluxClient

final class BluxErrorTests: XCTestCase {
    func testLengthOutOfRangeBetween_ErrorDescription() {
        let error = BluxError.LengthOutOfRangeBetween("name", 1, 10)
        XCTAssertEqual(error.errorDescription, "The length of `name` must be between 1 and 10.")
    }

    func testLengthOutOfRangeGe_ErrorDescription() {
        let error = BluxError.LengthOutOfRangeGe("page", 5)
        XCTAssertEqual(error.errorDescription, "The length of `page` must be greater than or equal to 5.")
    }

    func testValueOutOfRangeBetween_ErrorDescription() {
        let error = BluxError.ValueOutOfRangeBetween("price", 0.0, 100.0)
        XCTAssertEqual(error.errorDescription, "The value of `price` must be between 0.0 and 100.0.")
    }

    func testValueOutOfRangeGe_ErrorDescription() {
        let error = BluxError.ValueOutOfRangeGe("price", 0)
        XCTAssertEqual(error.errorDescription, "The value of `price` must be greater than or equal to 0.")
    }

    func testInvalidQuantity_ErrorDescription() {
        let error = BluxError.InvalidQuantity
        XCTAssertEqual(error.errorDescription, "Purchase quantity must be greater than 0.")
    }

    func testIsLocalizedError() {
        let error: Error = BluxError.InvalidQuantity
        XCTAssertNotNil((error as? LocalizedError)?.errorDescription)
    }

    func testClientErrorHoldsMessageAndStatusCode() {
        let clientError = BluxError.ClientError(message: "Bad Request", httpStatusCode: 400)
        XCTAssertEqual(clientError.message, "Bad Request")
        XCTAssertEqual(clientError.httpStatusCode, 400)
    }

    func testClientErrorOptionalFields() {
        let clientError = BluxError.ClientError(message: nil, httpStatusCode: nil)
        XCTAssertNil(clientError.message)
        XCTAssertNil(clientError.httpStatusCode)
    }
}

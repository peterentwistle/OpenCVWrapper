import XCTest
@testable import OpenCVWrapper

class OpenCVWrapperTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertEqual(OpenCVWrapper().text, "Hello, World!")
    }


    static var allTests : [(String, (OpenCVWrapperTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}

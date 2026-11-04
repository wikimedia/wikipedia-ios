import XCTest
@testable import Wikipedia

final class RemoteNotificationRegistrationFailureTests: XCTestCase {

    func testLogMessageWithNilErrorFromObjectiveC() {
        // UIKit passed a nil NSError to didFailToRegisterForRemoteNotificationsWithError (crash in 2026.10.27 build 6206). Swift sees that as a non-optional Error that holds a null pointer.
        let nilError = unsafeBitCast(NSError?.none, to: (any Error).self)

        let message = RemoteNotificationRegistrationFailure.logMessage(for: nilError)

        XCTAssertEqual(message, "Remote notification registration failure: nil error")
    }

    func testLogMessageWithNSError() {
        let error = NSError(domain: "org.wikimedia.test", code: 3010, userInfo: [NSLocalizedDescriptionKey: "remote notifications are not supported in the simulator"])

        let message = RemoteNotificationRegistrationFailure.logMessage(for: error)

        XCTAssertEqual(message, "Remote notification registration failure: remote notifications are not supported in the simulator")
    }

    func testLogMessageWithSwiftError() {
        struct RegistrationError: LocalizedError {
            var errorDescription: String? { "swift error" }
        }

        let message = RemoteNotificationRegistrationFailure.logMessage(for: RegistrationError())

        XCTAssertEqual(message, "Remote notification registration failure: swift error")
    }
}

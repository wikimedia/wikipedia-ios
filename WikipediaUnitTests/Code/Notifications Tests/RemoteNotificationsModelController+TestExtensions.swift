import Foundation
@testable import WMF

extension RemoteNotificationsModelController {
    static func temporaryModelController() throws -> RemoteNotificationsModelController {
        let url = URL(fileURLWithPath: WMFRandomTemporaryPath())
        return try RemoteNotificationsModelController(containerURL: url)
    }
}

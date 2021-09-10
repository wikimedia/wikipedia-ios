import UIKit

/// Handle conditional presentation of Notifications Center
@objc public protocol NotificationsCenterPresentationDelegate: NSObjectProtocol {
    func userDidTapNotificationsCenter(from viewController: UIViewController?)
}

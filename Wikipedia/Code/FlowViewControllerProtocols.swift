import UIKit

/// View Controllers that have an editing element (Editor flow, User talk pages, Article description editor)
protocol EditingFlowViewController where Self: UIViewController {
    var shouldDisplayExitConfirmationAlert: Bool { get }
}

extension EditingFlowViewController {
    var shouldDisplayExitConfirmationAlert: Bool {
        return true
    }
}

/// View Controllers that are a part of the Notifications Center flow
protocol NotificationsCenterFlowViewController where Self: UIViewController {

    // hook called after the user taps a push notification while in the foregound.
    // use if needed to tweak the view hierarchy to display the Notifications Center
    func tappedPushNotification()
}

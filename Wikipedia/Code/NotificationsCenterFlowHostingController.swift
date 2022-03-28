import UIKit
import SwiftUI

class NotificationsCenterModalHostingController<Content>: UIHostingController<Content> where Content: View {
}

extension NotificationsCenterModalHostingController: NotificationsCenterFlowViewController {
    func tappedPushNotification() {
        dismiss(animated: true, completion: nil)
    }
}

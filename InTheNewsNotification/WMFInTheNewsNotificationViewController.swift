import UIKit
import UserNotifications
import UserNotificationsUI

class WMFInTheNewsNotificationViewController: UIViewController, UNNotificationContentExtension {

    @IBOutlet var label: UILabel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any required interface initialization here.
    }
    
    func didReceiveNotification(notification: UNNotification) {
        self.label?.text = notification.request.content.body
    }

}

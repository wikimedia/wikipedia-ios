import UIKit
import UserNotifications
import UserNotificationsUI
import WMFUI

class WMFInTheNewsNotificationViewController: UIViewController, UNNotificationContentExtension {
    @IBOutlet weak var imageView: UIImageView!

    @IBOutlet weak var readerCountLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var sparklineView: WMFSparklineView!
    @IBOutlet weak var imageViewWidth: NSLayoutConstraint!
    @IBOutlet var label: UILabel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any required interface initialization here.
    }
    
    func didReceiveNotification(notification: UNNotification) {
        self.label?.text = notification.request.content.body
    }

    func didReceive(response: UNNotificationResponse, completionHandler completion: (UNNotificationContentExtensionResponseOption) -> Swift.Void) {
        
    }
}

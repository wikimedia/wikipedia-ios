import UIKit
import UserNotifications
import UserNotificationsUI
import WMFUI

class WMFInTheNewsNotificationViewController: UIViewController, UNNotificationContentExtension {
    @IBOutlet weak var imageView: UIImageView!

    @IBOutlet weak var readerCountLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var sparklineView: WMFSparklineView!

    @IBOutlet weak var summaryLabel: UILabel!
    
    @IBOutlet weak var articleSubtitleLabel: UILabel!
    @IBOutlet weak var articleTitleLabel: UILabel!
    
    @IBOutlet weak var articleTitleLabelLeadingMargin: NSLayoutConstraint!
    @IBOutlet weak var summaryLabelLeadingMargin: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.hidden = true
        articleTitleLabelLeadingMargin.constant = summaryLabelLeadingMargin.constant
    }
    
    func didReceiveNotification(notification: UNNotification) {
        summaryLabel.text = notification.request.content.body
    }

    func didReceive(response: UNNotificationResponse, completionHandler completion: (UNNotificationContentExtensionResponseOption) -> Swift.Void) {
        
    }
}

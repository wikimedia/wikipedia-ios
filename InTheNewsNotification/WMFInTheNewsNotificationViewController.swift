import UIKit
import UserNotifications
import UserNotificationsUI
import WMFModel
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
    
    var marginWidthForVisibleImageView: CGFloat = 0
    
    var imageViewHidden = false {
        didSet {
            imageView.hidden = imageViewHidden
            if imageViewHidden {
                articleTitleLabelLeadingMargin.constant = summaryLabelLeadingMargin.constant
            } else {
                articleTitleLabelLeadingMargin.constant = marginWidthForVisibleImageView
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        marginWidthForVisibleImageView = articleTitleLabelLeadingMargin.constant
    }
    
    func didReceiveNotification(notification: UNNotification) {
        summaryLabel.text = notification.request.content.body
        let info = notification.request.content.userInfo
        let title = info[WMFNotificationInfoArticleTitleKey] as? String
        let extract = info[WMFNotificationInfoArticleExtractKey] as? String
        
        if let html = info[WMFNotificationInfoStoryHTMLKey] as? String {
            let font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody, compatibleWithTraitCollection: nil)
            let linkFont = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline, compatibleWithTraitCollection: nil)
            let attributedString = html.wmf_attributedStringByRemovingHTMLWithFont(font, linkFont: linkFont)
            summaryLabel.attributedText = attributedString
        }
        
        
        articleTitleLabel.text = title
        articleSubtitleLabel.text = extract
        
        self.imageViewHidden = false
        if let thumbnailURLString = info[WMFNotificationInfoThumbnailURLStringKey] as? String, let thumbnailURL = NSURL(string: thumbnailURLString) {
            imageView.wmf_setImageWithURL(thumbnailURL, detectFaces: false, onGPU: false, failure: { (error) in
                dispatch_async(dispatch_get_main_queue(), { 
                   self.imageViewHidden = true
                })
                }, success: {
                   
            })
        } else {
            self.imageViewHidden = true
        }
        
        if let viewCounts = info[WMFNotificationInfoViewCountsKey] as? [Double] {
            print(viewCounts)
        }
    }

    func didReceive(response: UNNotificationResponse, completionHandler completion: (UNNotificationContentExtensionResponseOption) -> Swift.Void) {
        
    }
}

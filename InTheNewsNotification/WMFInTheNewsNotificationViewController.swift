import UIKit
import UserNotifications
import UserNotificationsUI
import WMFModel
import WMFUI
import WMFUtilities

class WMFInTheNewsNotificationViewController: UIViewController, UNNotificationContentExtension, WMFAnalyticsContextProviding, WMFAnalyticsContentTypeProviding {
    @IBOutlet weak var imageView: UIImageView!

    @IBOutlet weak var statusView: UIVisualEffectView!
    @IBOutlet weak var statusLabel: UILabel!
    
    @IBOutlet weak var readerCountLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var sparklineView: WMFSparklineView!

    @IBOutlet weak var summaryLabel: UILabel!
    
    @IBOutlet weak var articleSubtitleLabel: UILabel!
    @IBOutlet weak var articleTitleLabel: UILabel!
    
    @IBOutlet weak var articleTitleLabelLeadingMargin: NSLayoutConstraint!
    @IBOutlet weak var summaryLabelLeadingMargin: NSLayoutConstraint!
    
    var marginWidthForVisibleImageView: CGFloat = 0
    
    var articleURL: NSURL?

    lazy var databaseStack: WMFDatabaseStack = {
        [unowned self] in
        WMFDatabaseStack.sharedInstance().setupStack()
        return WMFDatabaseStack.sharedInstance()
        }()
    
    deinit {
        databaseStack.tearDownStack()
    }
    
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
    
    func analyticsContext() -> String {
        return "notification"
    }
    
    func analyticsContentType() -> String {
        guard let articleHost = articleURL?.host else {
            return "unknown domain"
        }
        return articleHost
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        PiwikTracker.wmf_start()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        marginWidthForVisibleImageView = articleTitleLabelLeadingMargin.constant
    }
    
    func didReceiveNotification(notification: UNNotification) {
        statusView.hidden = true
        summaryLabel.text = notification.request.content.body
        let info = notification.request.content.userInfo
        let title = info[WMFNotificationInfoArticleTitleKey] as? String
        let extract = info[WMFNotificationInfoArticleExtractKey] as? String
        
        if let articleURLString = info[WMFNotificationInfoArticleURLStringKey] as? String {
            articleURL = NSURL(string: articleURLString)
        }
        
        PiwikTracker.sharedInstance()?.wmf_logActionPreviewInContext(self, contentType: self, date: NSDate())
        
        do {
            if let dictionary = info[WMFNotificationInfoFeedNewsStoryKey] as? [String: AnyObject],
                let newsStory = try MTLJSONAdapter.modelOfClass(WMFFeedNewsStory.self, fromJSONDictionary: dictionary) as? WMFFeedNewsStory,
                let html = newsStory.storyHTML  {
                let font = UIFont.preferredFontForTextStyle(UIFontTextStyleFootnote, compatibleWithTraitCollection: nil)
                let linkFont = UIFont.boldSystemFontOfSize(font.pointSize)
                let attributedString = html.wmf_attributedStringByRemovingHTMLWithFont(font, linkFont: linkFont)
                summaryLabel.attributedText = attributedString
            }
        } catch let error as NSError {
            DDLogError("erorr deserializing news story \(error)")
        }

        timeLabel.text = localizedStringForKeyFallingBackOnEnglish("in-the-news-currently-trending")
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
        
        guard let viewCountDict = info[WMFNotificationInfoViewCountsKey] as? NSDictionary else {
            readerCountLabel.text = ""
            return
        }
        
        let viewCounts = viewCountDict.wmf_pageViewsSortedByDate
        
        guard viewCounts.count > 0 else {
            readerCountLabel.text = ""
            return
        }
            
        sparklineView.dataValues = viewCounts
        sparklineView.showsVerticalGridlines = true
        sparklineView.updateMinAndMaxFromDataValues()
        
        guard let count = viewCounts.last else {
            readerCountLabel.text = ""
            return
        }
        
        readerCountLabel.text = NSNumberFormatter.localizedThousandsStringFromNumber(count)
    }

    func didReceiveNotificationResponse(response: UNNotificationResponse, completionHandler completion: (UNNotificationContentExtensionResponseOption) -> Void) {
        guard let articleURL = articleURL, let extensionContext = extensionContext else {
            completion(.Dismiss)
            return
        }
        
        switch response.actionIdentifier {
        case UNNotificationDismissActionIdentifier:
            completion(.Dismiss)
        case WMFInTheNewsNotificationSaveForLaterActionIdentifier:
            statusView.hidden = false
            statusLabel.text = localizedStringForKeyFallingBackOnEnglish("status-saving-for-later")
            PiwikTracker.sharedInstance()?.wmf_logActionSaveInContext(self, contentType: self)
            self.databaseStack.userStore.savedPageList.addSavedPageWithURL(articleURL)
            self.databaseStack.userStore.notifyWhenWriteTransactionsComplete({
                dispatch_async(dispatch_get_main_queue(), {
                    
                    self.statusView.hidden = false
                    self.statusLabel.text = localizedStringForKeyFallingBackOnEnglish("status-saved-for-later")
                    completion(.Dismiss)
                })
            })
        case WMFInTheNewsNotificationShareActionIdentifier:
            PiwikTracker.sharedInstance()?.wmf_logActionTapThroughInContext(self, contentType: self)
            completion(.DismissAndForwardAction)
        case WMFInTheNewsNotificationReadNowActionIdentifier:
            fallthrough
        case UNNotificationDefaultActionIdentifier:
            fallthrough
        default:
            guard let wikipediaSchemeURL = articleURL.wmf_wikipediaSchemeURL else {
                completion(.Dismiss)
                break
            }
            PiwikTracker.sharedInstance()?.wmf_logActionTapThroughInContext(self, contentType: self)
            extensionContext.openURL(wikipediaSchemeURL, completionHandler: { (didOpen) in
                completion(.Dismiss)
            })
        }
    }
}

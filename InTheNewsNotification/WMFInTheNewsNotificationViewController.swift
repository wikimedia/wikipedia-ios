import UIKit
import UserNotifications
import UserNotificationsUI
import WMF
import CocoaLumberjackSwift

class WMFInTheNewsNotificationViewController: ExtensionViewController, UNNotificationContentExtension {
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
    
    @IBOutlet var separators: [UIView]!
    
    var marginWidthForVisibleImageView: CGFloat = 0
    
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        guard viewIfLoaded != nil else {
            return
        }
        summaryLabel.textColor = theme.colors.primaryText
        articleTitleLabel.textColor = theme.colors.primaryText
        articleSubtitleLabel.textColor = theme.colors.secondaryText
        statusLabel.textColor = theme.colors.accent
        readerCountLabel.textColor = theme.colors.accent
        timeLabel.textColor = theme.colors.secondaryText
        sparklineView.apply(theme: theme)
        for separator in separators {
            separator.backgroundColor = theme.colors.border
        }
    }

    var articleURL: URL?
    
    var imageViewHidden = false {
        didSet {
            imageView.isHidden = imageViewHidden
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
    
    func didReceive(_ notification: UNNotification) {
        statusView.isHidden = true
        summaryLabel.text = notification.request.content.body
        let info = notification.request.content.userInfo
        let title = info[WMFNotificationInfoArticleTitleKey] as? String
        let extract = info[WMFNotificationInfoArticleExtractKey] as? String
        
        if let articleURLString = info[WMFNotificationInfoArticleURLStringKey] as? String {
            articleURL = URL(string: articleURLString)
        }
        
        do {
            if let dictionary = info[WMFNotificationInfoFeedNewsStoryKey] as? [String: AnyObject],
                let newsStory = try MTLJSONAdapter.model(of: WMFFeedNewsStory.self, fromJSONDictionary: dictionary) as? WMFFeedNewsStory,
                let html = newsStory.storyHTML  {
                let attributedString = html.byAttributingHTML(with: .footnote, boldWeight: .bold, matching: traitCollection, color: nil, linkColor: nil, tagMapping: ["a":"b"])
                summaryLabel.attributedText = attributedString
            }
        } catch let error as NSError {
            DDLogError("erorr deserializing news story \(error)")
        }

        timeLabel.text = WMFLocalizedString("in-the-news-currently-trending", value:"Currently trending", comment: "Currently trending - indicates that the story is trending right now")
        articleTitleLabel.text = title
        articleSubtitleLabel.text = extract
        
        self.imageViewHidden = false
        if let thumbnailURLString = info[WMFNotificationInfoThumbnailURLStringKey] as? String, let thumbnailURL = URL(string: thumbnailURLString) {
            imageView.wmf_setImage(with: thumbnailURL, detectFaces: false, onGPU: false, failure: { (error) in
                DispatchQueue.main.async(execute: { 
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
        
        guard let viewCounts = viewCountDict.wmf_pageViewsSortedByDate, !viewCounts.isEmpty else {
            readerCountLabel.text = ""
            return
        }
            
        sparklineView.dataValues = viewCounts
        sparklineView.showsVerticalGridlines = true
        
        guard let count = viewCounts.last else {
            readerCountLabel.text = ""
            return
        }
        
        readerCountLabel.text = NumberFormatter.localizedThousandsStringFromNumber(count)
    }

    func didReceive(_ response: UNNotificationResponse, completionHandler completion: @escaping (UNNotificationContentExtensionResponseOption) -> Void) {
        guard let articleURL = articleURL, let extensionContext = extensionContext else {
            completion(.dismiss)
            return
        }
        
        switch response.actionIdentifier {
        case UNNotificationDismissActionIdentifier:
            completion(.dismiss)
        case WMFInTheNewsNotificationSaveForLaterActionIdentifier:
            statusView.isHidden = false
            statusLabel.text = WMFLocalizedString("status-saving-for-later", value:"Saving for later...", comment: "Indicates to the user that the article is being saved for later")
            WidgetController.shared.startWidgetUpdateTask(completion) { (dataStore, updateTaskCompletion) in
                dataStore.viewContext.perform {
                    dataStore.savedPageList.addSavedPage(with: articleURL)
                    self.statusView.isHidden = false
                    self.statusLabel.text = WMFLocalizedString("status-saved-for-later", value:"Saved for later", comment: "Indicates to the user that the article has been saved for later")
                    updateTaskCompletion(.dismiss)
                }
            }
        case WMFInTheNewsNotificationShareActionIdentifier:
            completion(.dismissAndForwardAction)
        case WMFInTheNewsNotificationReadNowActionIdentifier:
            fallthrough
        case UNNotificationDefaultActionIdentifier:
            fallthrough
        default:
            guard let wikipediaSchemeURL = articleURL.replacingSchemeWithWikipediaScheme else {
                completion(.dismiss)
                break
            }
            extensionContext.open(wikipediaSchemeURL, completionHandler: { (didOpen) in
                completion(.dismiss)
            })
        }
    }

}

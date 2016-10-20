import UIKit
import NotificationCenter
import WMFUI

class WMFTodayContinueReadingWidgetViewController: UIViewController, NCWidgetProviding {
    @IBOutlet weak var imageView: UIImageView!

    @IBOutlet weak var daysAgoView: UIView!
    @IBOutlet weak var daysAgoLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var textLabel: UILabel!
    
    @IBOutlet weak var emptyView: UIView!
    @IBOutlet weak var emptyTitleLabel: UILabel!
    @IBOutlet weak var emptyDescriptionLabel: UILabel!

    @IBOutlet var imageWidthConstraint: NSLayoutConstraint!
    @IBOutlet var titleLabelTrailingConstraint: NSLayoutConstraint!
    
    var articleURL: NSURL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOSApplicationExtension 10.0, *) {
            
        } else {
            titleLabel.textColor = UIColor(white: 1, alpha: 1)
            textLabel.textColor = UIColor(white: 1, alpha: 1)
            emptyTitleLabel.textColor = UIColor(white: 1, alpha: 1)
            emptyDescriptionLabel.textColor = UIColor(white: 1, alpha: 0.7)
            daysAgoLabel.textColor = UIColor(white: 1, alpha: 0.7)
            daysAgoView.backgroundColor = UIColor(white: 0.3, alpha: 0.3)
        }
        
        emptyDescriptionLabel.text = localizedStringForKeyFallingBackOnEnglish("continue-reading-empty-title")
        emptyDescriptionLabel.text = localizedStringForKeyFallingBackOnEnglish("continue-reading-empty-description")
        updateView()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        updateView()
    }
    
    func widgetPerformUpdate(completionHandler: (NCUpdateResult) -> Void) {
        
        let didUpdate = updateView()
        
        if(didUpdate){
            completionHandler(.NewData)
            
        }else{
            completionHandler(.NoData)
        }
    }
    
    var emptyViewHidden: Bool = false {
        didSet {
            emptyView.hidden = emptyViewHidden
            
            titleLabel.hidden = !emptyViewHidden
            textLabel.hidden = !emptyViewHidden
            imageView.hidden = !emptyViewHidden
            daysAgoView.hidden = !emptyViewHidden
        }
    }

    var collapseImageAndWidenLabels: Bool = true {
        didSet {
            imageWidthConstraint.constant = collapseImageAndWidenLabels ? 0 : 86
            titleLabelTrailingConstraint.constant = collapseImageAndWidenLabels ? 0 : 10
            self.imageView.alpha = self.collapseImageAndWidenLabels ? 0 : 1
            self.view.layoutIfNeeded()
        }
    }
    
    func hasNewData() -> Bool{
        
        guard let session = SessionSingleton.sharedInstance() else {
            return false
        }

        session.dataStore.syncDataStoreToDatabase()
        
        guard let historyEntry = session.dataStore.historyList.mostRecentEntry() else {
            return false
        }
        let fragment = historyEntry.fragment
        
        let newURL = historyEntry.url.wmf_URLWithFragment(fragment)
        
        return newURL?.absoluteString != articleURL?.absoluteString
    }
    
    func updateView() -> Bool {
        
        if hasNewData() == false{
            return false
        }

        textLabel.text = nil
        titleLabel.text = nil
        imageView.image = nil
        collapseImageAndWidenLabels = true
        imageView.hidden = true
        daysAgoLabel.text = nil
        daysAgoView.hidden = true
        
        guard let session = SessionSingleton.sharedInstance() else {
            emptyViewHidden = false
            return false
        }
        
        guard let historyEntry = session.dataStore.historyList.mostRecentEntry() else {
            return false
        }
        
        let fragment = historyEntry.fragment
        articleURL = historyEntry.url.wmf_URLWithFragment(fragment)
        
        guard let lastReadArticleURL = articleURL else {
            emptyViewHidden = false
            return false
        }
        
        guard let article = session.dataStore.existingArticleWithURL(lastReadArticleURL) else {
            emptyViewHidden = false
            return false
        }
        
        emptyViewHidden = true
        
        if let subtitle = article.summary ?? article.entityDescription?.wmf_stringByCapitalizingFirstCharacter(){
            self.textLabel.text = subtitle
        } else {
            self.textLabel.text = nil
        }
        
        if let date = NSUserDefaults.wmf_userDefaults().wmf_appResignActiveDate() {
            self.daysAgoView.hidden = false
            self.daysAgoLabel.text = date.wmf_relativeTimestamp()
        } else {
            self.daysAgoView.hidden = true
        }
        
        
        self.titleLabel.text = article.displaytitle?.wmf_stringByRemovingHTML()
        
        
        if let string = article.imageURL, let imageURL = NSURL(string: string) {
            self.imageView.hidden = false
            self.imageView.wmf_setImageWithURL(imageURL, detectFaces: true, onGPU: true, failure: { (error) in
                self.collapseImageAndWidenLabels = true
            }) {
                self.collapseImageAndWidenLabels = false
            }
        } else {
            self.collapseImageAndWidenLabels = true
        }
        
        var fitSize = UILayoutFittingCompressedSize
        fitSize.width = view.bounds.size.width
        fitSize = view.systemLayoutSizeFittingSize(fitSize, withHorizontalFittingPriority: UILayoutPriorityRequired, verticalFittingPriority: UILayoutPriorityDefaultLow)
        preferredContentSize = fitSize
        
        return true
    }
    

    @IBAction func continueReading(sender: AnyObject) {
        let URLToOpen = articleURL?.wmf_wikipediaSchemeURL ?? NSUserActivity.wmf_baseURLForActivityOfType(.Explore)
        
        self.extensionContext?.openURL(URLToOpen, completionHandler: { (success) in
            
        })
    }


}


import UIKit
import NotificationCenter
import WMF

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
    
    var articleURL: URL?
    
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
        _ = updateView()
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.handleTapGestureRecognizer(_:))))
    }
    
    func handleTapGestureRecognizer(_ recognizer: UITapGestureRecognizer) {
        switch recognizer.state {
        case .ended:
            continueReading(self)
        default:
            break
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        _ = updateView()
    }
    
    func widgetPerformUpdate(_ completionHandler: (NCUpdateResult) -> Void) {
        
        let didUpdate = updateView()
        
        if(didUpdate){
            completionHandler(.newData)
            
        }else{
            completionHandler(.noData)
        }
    }
    
    var emptyViewHidden: Bool = false {
        didSet {
            emptyView.isHidden = emptyViewHidden
            
            titleLabel.isHidden = !emptyViewHidden
            textLabel.isHidden = !emptyViewHidden
            imageView.isHidden = !emptyViewHidden
            daysAgoView.isHidden = !emptyViewHidden
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
        
        guard let historyEntry = session.dataStore.historyList.mostRecentEntry() else {
            return false
        }
        let fragment = historyEntry.viewedFragment
        
        let newURL = (historyEntry.url as NSURL?)?.wmf_URL(withFragment: fragment)
        
        return newURL?.absoluteString != articleURL?.absoluteString
    }
    
    func updateView() -> Bool {
        
        if hasNewData() == false{
            return false
        }

        textLabel.text = nil
        titleLabel.text = nil
        imageView.image = nil
        imageView.isHidden = true
        daysAgoLabel.text = nil
        daysAgoView.isHidden = true
        
        guard let session = SessionSingleton.sharedInstance() else {
            emptyViewHidden = false
            return false
        }
        
        guard let historyEntry = session.dataStore.historyList.mostRecentEntry() else {
            return false
        }
        
        let fragment = historyEntry.viewedFragment
        articleURL = (historyEntry.url as NSURL?)?.wmf_URL(withFragment: fragment)
        
        guard let lastReadArticleURL = articleURL else {
            emptyViewHidden = false
            return false
        }
        
        guard let article = session.dataStore.existingArticle(with: lastReadArticleURL) else {
            emptyViewHidden = false
            return false
        }
        
        emptyViewHidden = true
        
        if let subtitle = article.summary ?? article.entityDescription?.wmf_stringByCapitalizingFirstCharacter(){
            self.textLabel.text = subtitle
        } else {
            self.textLabel.text = nil
        }
        
        if let date = UserDefaults.wmf_userDefaults().wmf_appResignActiveDate() {
            self.daysAgoView.isHidden = false
            self.daysAgoLabel.text = (date as NSDate).wmf_relativeTimestamp()
        } else {
            self.daysAgoView.isHidden = true
        }
        
        
        self.titleLabel.text = article.displaytitle?.wmf_stringByRemovingHTML()
        
        
        if #available(iOSApplicationExtension 10.0, *) {
            if let string = article.imageURL, let imageURL = URL(string: string) {
                self.collapseImageAndWidenLabels = false
                self.imageView.wmf_setImage(with: imageURL, detectFaces: true, onGPU: true, failure: { (error) in
                    self.collapseImageAndWidenLabels = true
                }) {
                    self.collapseImageAndWidenLabels = false
                }
            } else {
                self.collapseImageAndWidenLabels = true
            }
        } else {
            self.collapseImageAndWidenLabels = true
        }
        
        var fitSize = UILayoutFittingCompressedSize
        fitSize.width = view.bounds.size.width
        fitSize = view.systemLayoutSizeFitting(fitSize, withHorizontalFittingPriority: UILayoutPriorityRequired, verticalFittingPriority: UILayoutPriorityDefaultLow)
        preferredContentSize = fitSize
        
        return true
    }
    

    @IBAction func continueReading(_ sender: AnyObject) {
        let URL = articleURL as NSURL?
        let URLToOpen = URL?.wmf_wikipediaScheme ?? NSUserActivity.wmf_baseURLForActivity(of: .explore)
        
        self.extensionContext?.open(URLToOpen, completionHandler: { (success) in
            
        })
    }


}


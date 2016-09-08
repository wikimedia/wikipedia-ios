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

    var articleURL: NSURL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        emptyDescriptionLabel.text = localizedStringForKeyFallingBackOnEnglish("continue-reading-empty-title")
        emptyDescriptionLabel.text = localizedStringForKeyFallingBackOnEnglish("continue-reading-empty-description")
        widgetPerformUpdate { (result) in
            
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func widgetActiveDisplayModeDidChange(activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        
    }
    
    
    var emptyViewHidden: Bool = true {
        didSet {
            emptyView.hidden = emptyViewHidden
            
            titleLabel.hidden = !emptyViewHidden
            textLabel.hidden = !emptyViewHidden
            imageView.hidden = !emptyViewHidden
            daysAgoView.hidden = !emptyViewHidden
        }
    }
    
    func widgetPerformUpdate(completionHandler: (NCUpdateResult) -> Void) {
        textLabel.text = nil
        titleLabel.text = nil
        imageView.image = nil
        imageView.hidden = true
        daysAgoLabel.text = nil
        daysAgoView.hidden = true

        guard let session = SessionSingleton.sharedInstance() else {
            emptyViewHidden = false
            completionHandler(.NoData)
            return
        }
        
        articleURL = NSUserDefaults.wmf_userDefaults().wmf_openArticleURL()
            
        if articleURL == nil {
            let historyEntry = session.userDataStore.historyList.mostRecentEntry()
            let fragment: String? = historyEntry?.fragment
            articleURL = historyEntry?.url.wmf_URLWithFragment(fragment)
        }
        
        guard let lastReadArticleURL = articleURL else {
            emptyViewHidden = false
            completionHandler(.NoData)
            return
        }
        
        guard let article = session.dataStore.existingArticleWithURL(lastReadArticleURL) else {
            emptyViewHidden = false
            completionHandler(.NoData)
            return
        }
        
        emptyViewHidden = true
        
        if let section = article.sections?.sectionWithFragment(lastReadArticleURL.fragment) {
            self.textLabel.text = section.line?.wmf_stringByRemovingHTML()
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
                
            }) {
                
            }
        }
        
        completionHandler(.NewData)
        
    }

    @IBAction func continueReading(sender: AnyObject) {
        guard let URLToOpen = articleURL?.wmf_wikipediaSchemeURL ?? NSUserActivity.wmf_URLForActivityOfType(.Explore, parameters: nil) else {
            return
        }
        
        self.extensionContext?.openURL(URLToOpen, completionHandler: { (success) in
            
        })
    }


}


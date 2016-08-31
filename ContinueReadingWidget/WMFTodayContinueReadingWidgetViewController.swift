import UIKit
import NotificationCenter
import WMFUI

class WMFTodayContinueReadingWidgetViewController: UIViewController, NCWidgetProviding {
    @IBOutlet weak var imageView: UIImageView!

    @IBOutlet weak var daysAgoView: UIView!
    @IBOutlet weak var daysAgoLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var textLabel: UILabel!
    
    @IBOutlet weak var emptyLabel: UILabel!

    var articleURL: NSURL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        emptyLabel.text = localizedStringForKeyFallingBackOnEnglish("continue-reading-empty-label")
        widgetPerformUpdate { (result) in
            
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func widgetActiveDisplayModeDidChange(activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        
    }
    
    
    var emptyLabelHidden: Bool = true {
        didSet {
            emptyLabel.hidden = emptyLabelHidden
            
            titleLabel.hidden = !emptyLabelHidden
            textLabel.hidden = !emptyLabelHidden
            imageView.hidden = !emptyLabelHidden
            daysAgoView.hidden = !emptyLabelHidden
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
            emptyLabelHidden = false
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
            emptyLabelHidden = false
            completionHandler(.NoData)
            return
        }
        
        guard let article = session.dataStore.existingArticleWithURL(lastReadArticleURL) else {
            emptyLabelHidden = false
            completionHandler(.NoData)
            return
        }
        
        emptyLabelHidden = true
        
        if let section = article.sections.sectionWithFragment(lastReadArticleURL.fragment) {
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

        
        self.titleLabel.text = article.displaytitle
        
        
        if let imageURL = NSURL(string: article.imageURL) {
            self.imageView.hidden = false
            self.imageView.wmf_setImageWithURL(imageURL, detectFaces: true, onGPU: true, failure: { (error) in
                
            }) {
                
            }
        }
        
        completionHandler(.NewData)
        
    }

    @IBAction func continueReading(sender: AnyObject) {
        guard let URLToOpen = articleURL ?? NSUserActivity.wmf_URLForActivityOfType(.Explore) else {
            return
        }
        
        self.extensionContext?.openURL(URLToOpen, completionHandler: { (success) in
            
        })
    }


}


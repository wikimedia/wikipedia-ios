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
    
    var emptyViewHidden: Bool = true {
        didSet {
            emptyView.hidden = emptyViewHidden
            
            titleLabel.hidden = !emptyViewHidden
            textLabel.hidden = !emptyViewHidden
            imageView.hidden = !emptyViewHidden
            daysAgoView.hidden = !emptyViewHidden
        }
    }
    
    func hasNewData() -> Bool{
        
        guard let session = SessionSingleton.sharedInstance() else {
            return false
        }

        session.dataStore.syncDataStoreToDatabase()
        
        guard let historyEntry = session.userDataStore.historyList.mostRecentEntry() else {
            return false
        }
        let fragment = historyEntry.fragment
        
        let newURL = historyEntry.url.wmf_URLWithFragment(fragment)

        print("articleURL \(articleURL)")
        print("newURL \(newURL)")
        
        return newURL.absoluteString != articleURL?.absoluteString

    }
    
    func updateView() -> Bool {
        
        if hasNewData() == false{
            return false
        }

        textLabel.text = nil
        titleLabel.text = nil
        imageView.image = nil
        imageView.hidden = true
        daysAgoLabel.text = nil
        daysAgoView.hidden = true
        
        guard let session = SessionSingleton.sharedInstance() else {
            emptyViewHidden = false
            return false
        }
        
        guard let historyEntry = session.userDataStore.historyList.mostRecentEntry() else {
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
        
        return true
    }
    

    @IBAction func continueReading(sender: AnyObject) {
        guard let URLToOpen = articleURL?.wmf_wikipediaSchemeURL ?? NSUserActivity.wmf_URLForActivityOfType(.Explore, parameters: nil) else {
            return
        }
        
        self.extensionContext?.openURL(URLToOpen, completionHandler: { (success) in
            
        })
    }


}


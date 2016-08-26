import UIKit
import NotificationCenter
import WMFUI

class WMFTodayContinueReadingWidgetViewController: UIViewController, NCWidgetProviding {
    @IBOutlet weak var imageView: UIImageView!

    @IBOutlet weak var daysAgoLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var textLabel: UILabel!
    
    var articleURL: NSURL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.imageView.clipsToBounds = true
        #if DEBUG
            NSUserDefaults.wmf_userDefaults().wmf_setOpenArticleURL(NSURL(string: "https://en.wikipedia.org/wiki/Barack_Obama#2012_presidential_campaign"))
        #endif
        widgetPerformUpdate { (result) in
            
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func widgetActiveDisplayModeDidChange(activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        
    }
    
    func widgetPerformUpdate(completionHandler: (NCUpdateResult) -> Void) {
        guard let openArticleURL = NSUserDefaults.wmf_userDefaults().wmf_openArticleURL() else {
            articleURL = nil
            completionHandler(.NoData)
            return
        }
        
        articleURL = openArticleURL
        
        guard let article = SessionSingleton.sharedInstance().dataStore.existingArticleWithURL(openArticleURL) else {
            completionHandler(.NoData)
            return
        }
        
        if let section = article.sections.sectionWithFragment(openArticleURL.fragment) {
            self.textLabel.text = section.line?.wmf_stringByRemovingHTML()
        } else {
            self.textLabel.text = nil
        }
        
        if let date = NSUserDefaults.wmf_userDefaults().wmf_appResignActiveDate() {
            self.daysAgoLabel.hidden = false
            self.daysAgoLabel.text = date.wmf_relativeTimestamp()
        } else {
            self.daysAgoLabel.hidden = true
        }

        
        self.titleLabel.text = article.displaytitle
        
        
        if let imageURL = NSURL(string: article.imageURL) {
            self.imageView.wmf_setImageWithURL(imageURL, detectFaces: true, onGPU: true, failure: { (error) in
                
            }) {
                
            }
        }
        

        completionHandler(.NewData)
        
    }

    @IBAction func continueReading(sender: AnyObject) {
        guard let URLToOpen = articleURL else {
            return
        }
        
        self.extensionContext?.openURL(URLToOpen, completionHandler: { (success) in
            
        })
    }


}


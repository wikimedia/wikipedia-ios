import UIKit
import NotificationCenter
import WMFUI

class WMFTodayContinueReadingWidgetViewController: UIViewController, NCWidgetProviding {
    @IBOutlet weak var imageView: UIImageView!

    @IBOutlet weak var daysAgoLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var textLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.imageView.clipsToBounds = true
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
            completionHandler(.NoData)
            return
        }
        
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

}


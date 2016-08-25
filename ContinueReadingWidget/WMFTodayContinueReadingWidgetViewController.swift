import UIKit
import NotificationCenter
import WMFUI

class WMFTodayContinueReadingWidgetViewController: UIViewController, NCWidgetProviding {
    @IBOutlet weak var imageView: UIImageView!

    @IBOutlet weak var label: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()

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
        
        print("\(article)")
        self.label.text = article.displaytitle
        if let URL = NSURL(string: article.thumbnailURL) {
            self.imageView.wmf_setImageWithURL(URL, detectFaces: true, onGPU: true, failure: { (error) in
                
            }) {
                
            }
        }
        

        completionHandler(.NewData)
        
    }

}


import UIKit
import WMF

class TalkPageViewController: ViewController {
    
    private let talkPageTitle: String
    private let siteURL: URL
    
    convenience init?(url: URL, theme: Theme) {
        guard let talkPageTitle = url.wmf_title,
              let siteURL = (url as NSURL).wmf_site else {
            return nil
        }
        self.init(talkPageTitle: talkPageTitle, siteURL: siteURL, theme: theme)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    required init(talkPageTitle: String, siteURL: URL, theme: Theme) {
        self.talkPageTitle = talkPageTitle
        self.siteURL = siteURL
        super.init(theme: theme)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "New talk page beta testing"
        view = UIView()
        view.backgroundColor = self.theme.colors.baseBackground
    }
    
}

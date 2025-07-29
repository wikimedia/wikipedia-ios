import UIKit
import Capture

class ThemeableViewController: UIViewController, Themeable {
    var theme: Theme = Theme.standard
    
    func apply(theme: Theme) {
        self.theme = theme
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        apply(theme: theme)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Log screen view to Bitdrift
        let screenName = String(describing: type(of: self))
        Logger.logScreenView(screenName: screenName)
    }
}

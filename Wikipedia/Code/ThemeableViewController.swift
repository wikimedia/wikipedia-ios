import UIKit

class ThemeableViewController: UIViewController, Themeable {
    var theme: Theme = Theme.standard
    
    func apply(theme: Theme) {
        self.theme = theme
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        apply(theme: theme)
    }
}

import UIKit

class ThemeableViewController: UIViewController, Themeable {
    var theme: Theme = Theme.standard

    override func viewDidLoad() {
        super.viewDidLoad()
        apply(theme: theme)
    }
    
    func apply(theme: Theme) {
        self.theme = theme
    }
}

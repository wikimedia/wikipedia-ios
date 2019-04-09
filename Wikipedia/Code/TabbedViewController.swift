import UIKit

class TabbedViewController: UIViewController {
    private var theme = Theme.standard
}

extension TabbedViewController: Themeable {
    func apply(theme: Theme) {
        guard viewIfLoaded != nil else {
            self.theme = theme
            return
        }
        view.backgroundColor = theme.colors.baseBackground
    }
}

import UIKit

class TabbedViewController: UIViewController {
    private var theme = Theme.standard
}

extension TabbedViewController: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        view.backgroundColor = theme.colors.paperBackground
    }
}

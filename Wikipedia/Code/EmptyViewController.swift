import UIKit
import WMF
import WMFComponents

/// Shows one empty view that fills the view controller's view.
class EmptyViewController: UIViewController {
    private var emptyView: WMFEmptyHostingView?
    var theme: Theme = .standard

    var type: WMFEmptyViewType? {
        didSet {
            guard oldValue != type else {
                return
            }
            emptyView?.removeFromSuperview()
            emptyView = type?.makeView()
            if let emptyView {
                view.wmf_addSubviewWithConstraintsToEdges(emptyView)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        apply(theme: theme)
    }
}

extension EmptyViewController: Themeable {
    func apply(theme: Theme) {
        self.theme = theme

        guard viewIfLoaded != nil else {
            return
        }

        // The empty view draws its own background. This color shows only while there is no empty view.
        view.backgroundColor = theme.colors.midBackground
    }
}

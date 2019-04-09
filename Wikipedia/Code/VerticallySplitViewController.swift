import UIKit

class VerticallySplitViewController: UIViewController {
    @IBOutlet private weak var topView: UIView!
    @IBOutlet private weak var bottomView: UIView!

    private let topViewController: UIViewController & Themeable
    private let bottomViewController: UIViewController & Themeable

    private var theme = Theme.standard

    init(topViewController: UIViewController & Themeable, bottomViewController: UIViewController & Themeable) {
        self.topViewController = topViewController
        self.bottomViewController = bottomViewController
        super.init(nibName: "VerticallySplitViewController", bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        wmf_add(childController: topViewController, andConstrainToEdgesOfContainerView: topView)
        wmf_add(childController: bottomViewController, andConstrainToEdgesOfContainerView: bottomView)
        apply(theme: theme)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension VerticallySplitViewController: Themeable {
    func apply(theme: Theme) {
        guard viewIfLoaded != nil else {
            self.theme = theme
            return
        }
        topViewController.apply(theme: theme)
        bottomViewController.apply(theme: theme)
        view.backgroundColor = bottomViewController.view.backgroundColor
    }
}

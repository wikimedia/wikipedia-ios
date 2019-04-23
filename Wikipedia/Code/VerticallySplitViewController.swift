import UIKit

class VerticallySplitViewController: UIViewController {
    @IBOutlet private weak var topView: UIView!
    @IBOutlet private weak var bottomView: UIView!
    @IBOutlet private weak var bottomViewHeightConstraint: NSLayoutConstraint?
    private var bottomViewHeightConstraintOriginalMultiplier: CGFloat = 0.6

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
        bottomViewHeightConstraintOriginalMultiplier = bottomViewHeightConstraint?.multiplier ?? 0.6
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func extendBottomViewToFullHeight(multiplier: CGFloat) {
        let constant: CGFloat
        if let currentMultiplier = bottomViewHeightConstraint?.multiplier {
            constant = view.bounds.height * abs(multiplier - currentMultiplier)
        } else {
            constant = 0
        }
        bottomViewHeightConstraint?.constant = constant
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }

    func collapseBottomViewToOriginialHeight() {
        bottomViewHeightConstraint?.constant = 0
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
}

extension VerticallySplitViewController: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        topViewController.apply(theme: theme)
        bottomViewController.apply(theme: theme)
        if let navigationController = bottomViewController as? UINavigationController {
            view.backgroundColor = navigationController.topViewController?.view.backgroundColor
        } else {
            view.backgroundColor = bottomViewController.view.backgroundColor
        }
    }
}

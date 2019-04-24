import UIKit

class VerticallySplitViewController: UIViewController {
    @IBOutlet private weak var topView: UIView!
    @IBOutlet private weak var bottomView: UIView!
    @IBOutlet private weak var bottomViewHeightConstraint: NSLayoutConstraint?

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

    func extendBottomViewToFullHeight(multiplier: CGFloat) {
        guard
            traitCollection.horizontalSizeClass == .compact,
            traitCollection.verticalSizeClass == .regular
        else {
            return
        }
        let constant: CGFloat
        if let currentMultiplier = bottomViewHeightConstraint?.multiplier {
            constant = view.bounds.height * abs(multiplier - currentMultiplier)
        } else {
            constant = 0
        }
        UIView.animate(withDuration: 0.3) {
            self.view.transform = CGAffineTransform(translationX: 0, y: 0 - constant)
        }
    }

    func collapseBottomViewToOriginialHeight() {
        guard
            traitCollection.horizontalSizeClass == .compact,
            traitCollection.verticalSizeClass == .regular
        else {
            return
        }
        UIView.animate(withDuration: 0.3) {
            self.view.transform = CGAffineTransform.identity
        }
    }

    private var transformBeforeRotation: CGAffineTransform?
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in
            self.view.transform = CGAffineTransform.identity
        })
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

import UIKit

class WelcomeViewController: UIViewController {
    var theme = Theme.standard

    init(theme: Theme, viewControllers: [UIViewController & Themeable]) {
        self.theme = theme
        super.init(nibName: nil, bundle: nil)
        addPageViewController(with: viewControllers)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        apply(theme: theme)
    }

    private func addPageViewController(with viewControllers: [UIViewController & Themeable]) {
        let pageViewController = WelcomePageViewController(viewControllers: viewControllers)
        addChild(pageViewController)
        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.wmf_addSubviewWithConstraintsToEdges(pageViewController.view)
        pageViewController.didMove(toParent: self)
        pageViewController.apply(theme: theme)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return theme.preferredStatusBarStyle
    }
}

extension WelcomeViewController: Themeable {
    func apply(theme: Theme) {
        guard viewIfLoaded != nil else {
            self.theme = theme
            return
        }
        view.backgroundColor = theme.colors.midBackground
    }
}

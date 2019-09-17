import UIKit

class WelcomeViewController: UIViewController {
    private var theme = Theme.standard
    private let completion: () -> Void

    init(theme: Theme, viewControllers: [UIViewController & Themeable], completion: @escaping () -> Void) {
        self.completion = completion
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

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        completion()
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
        
        for child in children {
            guard let themeable = child as? Themeable else {
                continue
            }
            themeable.apply(theme: theme)
        }
    }
}

import UIKit

class TabbedViewController: UIViewController {
    private var theme = Theme.standard
}

extension TabbedViewController: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
final class TabbedViewController: ViewController {
    private let viewControllers: [UIViewController & Themeable]

    private lazy var tabsView: TabsView = {
        var underlineButtons = [UnderlineButton]()
        for (index, viewController) in viewControllers.enumerated() {
            let underlineButton = UnderlineButton()
            underlineButton.setTitle(viewController.title, for: .normal)
            underlineButton.sizeToFit()
            underlineButton.tag = index
            underlineButton.addTarget(self, action: #selector(didSelectViewController(_:)), for: .touchUpInside)
            underlineButtons.append(underlineButton)
        }
        return TabsView(buttons: underlineButtons)
    }()

    init(viewControllers: [UIViewController & Themeable]) {
        self.viewControllers = viewControllers
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Hello"
        navigationBar.addUnderNavigationBarView(tabsView)
    }

    @objc private func didSelectViewController(_ sender: UIButton) {
        print("")
    }

    // MARK: Themeable

    override func apply(theme: Theme) {
        super.apply(theme: theme)
        view.backgroundColor = theme.colors.paperBackground
        tabsView.apply(theme: theme)
    }
}

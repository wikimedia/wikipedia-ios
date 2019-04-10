import UIKit

final fileprivate class TabsView: UIView, Themeable {
    let buttons: [UIButton]

    required init(buttons: [UIButton]) {
        self.buttons = buttons
        super.init(frame: .zero)
        let stackView = UIStackView(arrangedSubviews: buttons)
        wmf_addSubviewWithConstraintsToEdges(stackView)
        print("")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func apply(theme: Theme) {
        backgroundColor = UIColor.purple
        buttons.forEach { $0.tintColor = theme.colors.link }
    }
}

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
        navigationBar.displayType = .hidden
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

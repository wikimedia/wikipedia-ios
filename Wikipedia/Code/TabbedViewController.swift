import UIKit

final fileprivate class TabsView: UIView, Themeable {
    private let buttons: [UIButton]

    init(buttons: [UIButton]) {
        self.buttons = buttons
        super.init(frame: .zero)
        let stackView = UIStackView(arrangedSubviews: buttons)
        stackView.distribution = .fillEqually
        wmf_addSubview(stackView, withConstraintsToEdgesWithInsets: UIEdgeInsets(top: 16, left: 12, bottom: 0, right: 12))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func deselectButton(at index: Int) {
        guard index < buttons.count else {
            return
        }
        buttons[index].isSelected = false
    }

    func apply(theme: Theme) {
        for button in buttons {
            button.setTitleColor(theme.colors.secondaryText, for: .normal)
            button.tintColor = theme.colors.link
        }
    }
}

final fileprivate class SearchView: UIView, Themeable {
    private let searchBar: UISearchBar

    init(searchBarDelegate: UISearchBarDelegate) {
        searchBar = UISearchBar()
        searchBar.placeholder = CommonStrings.searchTitle
        searchBar.delegate = searchBarDelegate
        searchBar.returnKeyType = .search
        searchBar.searchBarStyle = .minimal
        searchBar.showsCancelButton = false
        super.init(frame: .zero)
        wmf_addSubview(searchBar, withConstraintsToEdgesWithInsets: UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func apply(theme: Theme) {

    }
}

final class TabbedViewController: ViewController {
    private let viewControllers: [UIViewController & Themeable]
    private let extendedViews: [UIView]?
    private var selectedIndex = 0

    private lazy var tabsView: TabsView = {
        var underlineButtons = [UnderlineButton]()
        for (index, viewController) in viewControllers.enumerated() {
            let underlineButton = UnderlineButton()
            assert(viewController.title != nil, "View controller should have a title, otherwise button will be empty")
            underlineButton.setTitle(viewController.title, for: .normal)
            underlineButton.underlineHeight = 2
            underlineButton.useDefaultFont = false
            underlineButton.titleLabel?.font = UIFont.wmf_font(.callout)
            underlineButton.tag = index
            if index == selectedIndex {
                underlineButton.isSelected = true
            }
            underlineButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 16, right: 0)
            underlineButton.addTarget(self, action: #selector(didSelectViewController(_:)), for: .touchUpInside)
            underlineButtons.append(underlineButton)
        }
        return TabsView(buttons: underlineButtons)
    }()

    init(viewControllers: [UIViewController & Themeable], extendedViews: [UIView]? = nil) {
        self.viewControllers = viewControllers
        self.extendedViews = extendedViews
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationBar.displayType = .hidden
        navigationBar.addUnderNavigationBarView(tabsView)

        showViewControllerWithExtendedView(at: selectedIndex)
    }

    @objc private func didSelectViewController(_ sender: UIButton) {
        tabsView.deselectButton(at: selectedIndex)
        sender.isSelected = true
        selectedIndex = sender.tag

        for child in children {
            child.view.removeFromSuperview()
            child.willMove(toParent: nil)
            child.removeFromParent()
        }

        showViewControllerWithExtendedView(at: selectedIndex)
    }

    private func showViewControllerWithExtendedView(at index: Int) {
        guard let selectedViewController = viewControllers[safeIndex: index] else {
            return
        }
        wmf_add(childController: selectedViewController, andConstrainToEdgesOfContainerView: view, belowSubview: navigationBar)

        navigationBar.removeExtendedNavigationBarView()
        guard let extendedView = extendedViews?[safeIndex: index] else {
            return
        }
        navigationBar.addExtendedNavigationBarView(extendedView)
    }

    // MARK: Themeable

    override func apply(theme: Theme) {
        super.apply(theme: theme)
        view.backgroundColor = theme.colors.paperBackground
        tabsView.apply(theme: theme)
    }
}

private extension Array {
    subscript(safeIndex index: Int) -> Element? {
        guard index >= 0, index < endIndex else {
            return nil
        }
        return self[index]
    }
}

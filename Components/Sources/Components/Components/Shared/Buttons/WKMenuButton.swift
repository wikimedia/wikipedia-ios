import Foundation
import UIKit

/// A button that displays a `UIMenu` when triggering its primary action
public class WKMenuButton: WKComponentView {

    // MARK: - Nested Types

    public typealias MenuItem = Configuration.MenuItem

    public struct Configuration {

		// MARK: - Nested Types

        public struct MenuItem: Equatable {
            public let id = UUID()
            let title: String
            let image: UIImage?
            let attributes: UIMenu.Attributes

            public init(title: String, image: UIImage? = nil, attributes: UIMenu.Attributes = []) {
                self.title = title
                self.image = image
                self.attributes = attributes
            }
        }

        // MARK: - Properties

        var title: String?
        let image: UIImage?
        let primaryColor: KeyPath<WKTheme, UIColor>
        public let menuItems: [MenuItem]

		// MARK: - Public

        public init(title: String? = nil, image: UIImage? = nil, primaryColor: KeyPath<WKTheme, UIColor>,  menuItems: [MenuItem]) {
            self.title = title
            self.image = image
            self.primaryColor = primaryColor
            self.menuItems = menuItems
        }
		
	}

    // MARK: - Properties

    public weak var delegate: WKMenuButtonDelegate?
    public private(set) var configuration: Configuration

    // MARK: - UI Elements

    private lazy var button: WKButton = {
        let button = WKButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(userDidTap), for: .touchDown)
        return button
    }()

    // MARK: - Public

    public required init(configuration: Configuration) {
        self.configuration = configuration
        super.init(frame: .zero)
        setup()
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func updateTitle(_ title: String?) {
        configuration.title = title
        configure()
    }

	// MARK: - Setup

    public override var intrinsicContentSize: CGSize {
        return button.intrinsicContentSize
    }

    private func setup() {
        addSubview(button)
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: leadingAnchor),
            button.trailingAnchor.constraint(equalTo: trailingAnchor),
            button.topAnchor.constraint(equalTo: topAnchor),
            button.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        button.showsMenuAsPrimaryAction = true

        configure()
    }

    private func configure() {
        button.menu = generateMenu()
        button.backgroundColor = theme[keyPath: configuration.primaryColor].withAlphaComponent(0.15)
        button.tintColor = theme[keyPath: configuration.primaryColor]
        button.setTitleColor(theme[keyPath: configuration.primaryColor], for: .normal)
        button.titleLabel?.font = WKFont.for(.boldFootnote)
        button.setTitle(configuration.title, for: .normal)
        button.setImage(configuration.image, for: .normal)

        button.adjustsImageSizeForAccessibilityContentSizeCategory = true
        button.adjustsImageWhenHighlighted = false

        button.layer.cornerRadius = 8
        button.layer.cornerCurve = .continuous

        if effectiveUserInterfaceLayoutDirection == .leftToRight {
            button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: -8)
            button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 8, bottom: 8, right: 16)
        } else {
            button.titleEdgeInsets = UIEdgeInsets(top: 0, left: -8, bottom: 0, right: 4)
            button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 16, bottom: 8, right: 8)
        }
    }

    private func generateMenu() -> UIMenu {
        var actions: [UIAction] = []
        for menuItem in configuration.menuItems.reversed() {
            let action = UIAction(title: menuItem.title, image: menuItem.image, attributes: menuItem.attributes, handler: { [weak self] _ in
                self?.userDidTapMenuItem(menuItem)
            })

            actions.append(action)
        }

        return UIMenu(children: actions)
    }

    // MARK: - Button Actions

    private func userDidTapMenuItem(_ item: MenuItem) {
        delegate?.wkMenuButton(self, didTapMenuItem: item)
    }

    @objc private func userDidTap() {
        delegate?.wkMenuButtonDidTap(self)
    }

    // MARK: - Component Conformance

    public override func appEnvironmentDidChange() {
        configure()
    }
}

import Foundation
import UIKit

/// A button that displays a `UIMenu` when triggering its primary action
public class WMFSmallMenuButton: WMFComponentView {

    // MARK: - Nested Types

    public typealias MenuItem = Configuration.MenuItem

    public struct Configuration {

		// MARK: - Nested Types

        public struct MenuItem: Equatable, Identifiable {
            public let id = UUID()
            public let title: String
            let image: UIImage?
            let attributes: UIMenu.Attributes

            public init(title: String, image: UIImage? = nil, attributes: UIMenu.Attributes = []) {
                self.title = title
                self.image = image
                self.attributes = attributes
            }
        }

        // MARK: - Properties

        public var title: String?
        let image: UIImage?
        let primaryColor: KeyPath<WMFTheme, UIColor>
        public let menuItems: [MenuItem]
		public var metadata: [String: Any] = [:]

		// MARK: - Public

		public init(title: String? = nil, image: UIImage? = nil, primaryColor: KeyPath<WMFTheme, UIColor>,  menuItems: [MenuItem], metadata: [String: Any] = [:]) {
            self.title = title
            self.image = image
            self.primaryColor = primaryColor
            self.menuItems = menuItems
			self.metadata = metadata
        }
		
	}

    // MARK: - Properties

    public weak var delegate: WMFSmallMenuButtonDelegate?
    public private(set) var configuration: Configuration

    // MARK: - UI Elements

    private lazy var button: UIButton = {
        let buttonConfig = createButtonConfig()
        
        let button = UIButton(configuration: buttonConfig, primaryAction: nil)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.showsMenuAsPrimaryAction = true
        button.addTarget(self, action: #selector(userDidTap), for: .touchDown)
        button.menu = generateMenu()
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
        let buttonConfig = createButtonConfig()
        button.configuration = buttonConfig
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
            button.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
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
    
    private func createButtonConfig() -> UIButton.Configuration {
        
        var buttonConfig = UIButton.Configuration.filled()
        buttonConfig.image = configuration.image
        buttonConfig.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: UIFontMetrics.default.scaledValue(for: 13))
        buttonConfig.imagePadding = 6
        buttonConfig.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)

        var container = AttributeContainer()
        container.font = WMFFont.for(.boldFootnote)
        container.foregroundColor = theme[keyPath: configuration.primaryColor]
        if let title = configuration.title {
            buttonConfig.attributedTitle = AttributedString(title, attributes: container)
        }

        buttonConfig.baseForegroundColor = theme[keyPath: configuration.primaryColor]
        buttonConfig.background.backgroundColor = theme[keyPath: configuration.primaryColor].withAlphaComponent(0.15)
        
        buttonConfig.background.cornerRadius = 8
        buttonConfig.image = configuration.image
        
        return buttonConfig
    }

    // MARK: - Button Actions

    private func userDidTapMenuItem(_ item: MenuItem) {
        delegate?.wmfMenuButton(self, didTapMenuItem: item)
    }
    
    @objc private func userDidTap() {
        delegate?.wmfMenuButtonDidTap(self)
    }

    // MARK: - Component Conformance

    public override func appEnvironmentDidChange() {
        let buttonConfig = createButtonConfig()
        button.configuration = buttonConfig
    }
}

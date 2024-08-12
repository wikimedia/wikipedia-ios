import WMFComponents

/// A Themeable UIBarButtonItem with status text that mimics Apple Mail
class StatusTextBarButtonItem: UIBarButtonItem, Themeable {

    // MARK: - Properties

    private var theme: Theme?

    override var isEnabled: Bool {
        get {
            return super.isEnabled
        } set {
            super.isEnabled = newValue

            if let theme = theme {
                apply(theme: theme)
            }
        }
    }

    // MARK: - UI Elements

    fileprivate var containerView: UIView?

    lazy var label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = WMFFont.for(.caption1)
        label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        return label
    }()

    // MARK: - Lifecycle

    @objc convenience init(text: String) {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false

        self.init(customView: containerView)

        self.containerView = containerView
        label.text = text

        containerView.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            label.topAnchor.constraint(equalTo: containerView.topAnchor),
            label.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }

    // MARK: - Themeable

    public func apply(theme: Theme) {
        self.theme = theme
        tintColor = isEnabled ? theme.colors.link : theme.colors.disabledLink
        label.textColor = theme.colors.primaryText
    }

}

import WMFComponents

class NotificationsCenterDetailActionCell: UITableViewCell, ReusableCell {

    // MARK: - UI Elements

    lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.distribution = .fill
        return stackView
    }()

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = UIApplication.shared.wmf_isRTL ? .right : .left
        label.font = WMFFont.for(.callout)
        label.numberOfLines = 1
        return label
    }()

    lazy var destinationLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = UIApplication.shared.wmf_isRTL ? .left : .right
        label.font = WMFFont.for(.footnote)
        label.numberOfLines = 1
        return label
    }()

    // MARK: - Properties

    var action: NotificationsCenterAction?
    var theme: Theme = .light

    // MARK: - Lifecycle

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        action = nil
    }

    func setup() {
        contentView.addSubview(stackView)

        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(HorizontalSpacerView.spacerWith(space: 3))
        stackView.addArrangedSubview(destinationLabel)

        guard let imageView = imageView else {
            return
        }

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalToSystemSpacingAfter: imageView.trailingAnchor, multiplier: 2),
            stackView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor)
        ])

        titleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        destinationLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    // MARK: - Configuration

    func configure(action: NotificationsCenterAction?, theme: Theme) {
        self.theme = theme

        backgroundColor = theme.colors.paperBackground
        selectedBackgroundView = UIView()
        selectedBackgroundView?.backgroundColor = theme.colors.midBackground

        imageView?.tintColor = theme.colors.link
        titleLabel.textColor = theme.colors.link
        destinationLabel.textColor = theme.colors.secondaryText

        guard let action = action else { return }

        self.action = action

        if let actionData = action.actionData {
            let imageType = actionData.iconType
            titleLabel.text = actionData.text
            destinationLabel.text = actionData.destinationText
            switch imageType {
            case .custom(let name):
                imageView?.image = UIImage(named: name)
            case .system(let name):
                imageView?.image = UIImage(systemName: name)
            case .none:
                break
            }
        }
    }

}

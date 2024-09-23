import WMFComponents

class NotificationsCenterDetailContentCell: UITableViewCell, ReusableCell {

    // MARK: - Properties

    lazy var contentLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        return label
    }()

    // MARK: - Lifecycle

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup() {
        selectionStyle = .none
        
        contentView.addSubview(contentLabel)

        NSLayoutConstraint.activate([
            contentLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            contentLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            contentLabel.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            contentLabel.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor)
        ])
    }

    // MARK: - Configuration

    func configure(viewModel: NotificationsCenterDetailViewModel, theme: Theme) {
        backgroundColor = theme.colors.paperBackground

        let bodyContent = viewModel.contentBody != nil ? "\n\n\(viewModel.contentBody!)" : ""

        let boldAttribute = [NSAttributedString.Key.font: WMFFont.for(.boldCallout, compatibleWith: traitCollection)]
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 1.7
        let bodyTextAttributes = [
            NSAttributedString.Key.font: WMFFont.for(.callout, compatibleWith: traitCollection),
            NSAttributedString.Key.paragraphStyle: paragraphStyle
        ]

        let attributedTitle = NSMutableAttributedString(string: viewModel.contentTitle, attributes: boldAttribute)
        let attributedBody = NSMutableAttributedString(string: bodyContent, attributes: bodyTextAttributes)

        let attributedContentText = NSMutableAttributedString()
        attributedContentText.append(attributedTitle)
        attributedContentText.append(attributedBody)

        contentLabel.attributedText = attributedContentText
        contentLabel.textColor = theme.colors.primaryText
    }

}

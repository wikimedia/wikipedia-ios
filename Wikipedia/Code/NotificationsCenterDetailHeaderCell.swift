import WMFComponents

class NotificationsCenterDetailHeaderCell: UITableViewCell, ReusableCell {

    // MARK: - Properties

    lazy var mainStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.distribution = .fill
        return stackView
    }()

    lazy var labelStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = 3
        stackView.axis = .vertical
        return stackView
    }()

    lazy var detailLabelStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = 6
        stackView.axis = .horizontal
        return stackView
    }()

    lazy var leadingImageView: RoundedImageView = {
        let view = RoundedImageView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.imageView.contentMode = .scaleAspectFit
        view.layer.borderWidth = 2
        view.layer.borderColor = UIColor.clear.cgColor
        return view
    }()

    lazy var leadingImageContainer: UIView = {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        return container
    }()

    lazy var headerLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.font = WMFFont.for(.boldCallout, compatibleWith: traitCollection)
        return label
    }()

    lazy var subheaderLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.font = WMFFont.for(.footnote, compatibleWith: traitCollection)
        label.textAlignment = effectiveUserInterfaceLayoutDirection == .rightToLeft ? .right : .left
        return label
    }()

    lazy var dateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.font = WMFFont.for(.footnote, compatibleWith: traitCollection)
        label.textAlignment = effectiveUserInterfaceLayoutDirection == .rightToLeft ? .left : .right
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

        contentView.addSubview(mainStackView)

        mainStackView.addArrangedSubview(leadingImageContainer)
        mainStackView.addArrangedSubview(labelStackView)

        labelStackView.addArrangedSubview(headerLabel)
        labelStackView.addArrangedSubview(detailLabelStackView)

        detailLabelStackView.addArrangedSubview(subheaderLabel)
        detailLabelStackView.addArrangedSubview(dateLabel)

        leadingImageContainer.addSubview(leadingImageView)

        NSLayoutConstraint.activate([
            leadingImageView.heightAnchor.constraint(equalToConstant: 37),
            leadingImageView.widthAnchor.constraint(equalToConstant: 37),
            leadingImageView.centerYAnchor.constraint(equalTo: leadingImageContainer.centerYAnchor),
            leadingImageView.leadingAnchor.constraint(equalTo: leadingImageContainer.leadingAnchor),

            leadingImageContainer.widthAnchor.constraint(equalToConstant: 45),
            leadingImageContainer.leadingAnchor.constraint(equalTo: mainStackView.leadingAnchor),
            leadingImageContainer.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            leadingImageContainer.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),

            mainStackView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            mainStackView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            mainStackView.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            mainStackView.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor)
        ])
    }

    // MARK: - Configuration

    func configure(viewModel: NotificationsCenterDetailViewModel, theme: Theme) {
        backgroundColor = theme.colors.paperBackground

        headerLabel.text = viewModel.headerTitle
        subheaderLabel.text = viewModel.headerSubtitle
        dateLabel.text = viewModel.headerDate

        headerLabel.textColor = theme.colors.primaryText
        subheaderLabel.textColor = theme.colors.secondaryText
        dateLabel.textColor = theme.colors.secondaryText

        leadingImageView.imageView.image = UIImage(named: viewModel.commonViewModel.notification.type.imageName)
        leadingImageView.tintColor = theme.colors.paperBackground
        leadingImageView.backgroundColor = viewModel.headerImageBackgroundColorWithTheme(theme)

        configureDetailLabelStackFor(sizeCategory: traitCollection.preferredContentSizeCategory)
    }

    // MARK: - Private

    fileprivate func configureDetailLabelStackFor(sizeCategory: UIContentSizeCategory) {
        if sizeCategory < .accessibilityMedium {
            detailLabelStackView.axis = .horizontal
            dateLabel.textAlignment = effectiveUserInterfaceLayoutDirection == .rightToLeft ? .left : .right
        } else {
            detailLabelStackView.axis = .vertical
            dateLabel.textAlignment = effectiveUserInterfaceLayoutDirection == .rightToLeft ? .right : .left
        }
    }

}

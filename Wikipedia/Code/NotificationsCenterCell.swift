import WMFComponents

protocol NotificationsCenterCellDelegate: AnyObject {
    func userDidTapMarkAsReadUnreadActionForCell(_ cell: NotificationsCenterCell)
    func userDidTapMoreActionForCell(_ cell: NotificationsCenterCell)
}

final class NotificationsCenterCell: UICollectionViewCell {

    // MARK: - Properties

    static let reuseIdentifier = "NotificationsCenterCell"
    static let swipeEdgeBuffer: CGFloat = 20

    fileprivate var theme: Theme = .light
    fileprivate(set) var viewModel: NotificationsCenterCellViewModel?

    weak var delegate: NotificationsCenterCellDelegate?

    // MARK: - UI Elements

    lazy var leadingImageView: RoundedImageView = {
        let view = RoundedImageView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.imageView.contentMode = .scaleAspectFit
        view.layer.borderWidth = 2
        view.layer.borderColor = UIColor.clear.cgColor
        return view
    }()

    lazy var projectSourceLabel: InsetLabelView = {
        let insetLabel = InsetLabelView()

        insetLabel.translatesAutoresizingMaskIntoConstraints = false
        insetLabel.label.setContentCompressionResistancePriority(.required, for: .vertical)
        insetLabel.label.font = WMFFont.for(.caption1, compatibleWith: traitCollection)
        insetLabel.label.adjustsFontForContentSizeCategory = true
        insetLabel.label.numberOfLines = 1
        insetLabel.label.text = "EN"
        insetLabel.label.textAlignment = .center

        insetLabel.layer.cornerRadius = 3
        insetLabel.layer.borderWidth = 1
        insetLabel.layer.borderColor = UIColor.black.cgColor
        insetLabel.insets = NSDirectionalEdgeInsets(top: 4, leading: 4, bottom: -4, trailing: -4)

        insetLabel.isHidden = true

        return insetLabel
    }()

    lazy var projectSourceImage: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(named: "wikimedia-project-commons")
        imageView.contentMode = .scaleAspectFit

        imageView.isHidden = true

        return imageView
    }()

    lazy var headerLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.font = WMFFont.for(.headline, compatibleWith: traitCollection)
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = effectiveUserInterfaceLayoutDirection == .rightToLeft ? .right : .left
        label.numberOfLines = 1
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.text = ""
        label.isUserInteractionEnabled = true
        return label
    }()

    lazy var subheaderLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.font = WMFFont.for(.subheadline, compatibleWith: traitCollection)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 1
        label.textAlignment = effectiveUserInterfaceLayoutDirection == .rightToLeft ? .right : .left
        label.text = ""
        return label
    }()

    lazy var messageSummaryLabel: UITextView = {
        let label = UITextView()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.setContentHuggingPriority(.defaultLow, for: .vertical)
        label.font = WMFFont.for(.callout, compatibleWith: traitCollection)
        label.adjustsFontForContentSizeCategory = true
        label.textContainer.lineBreakMode = .byTruncatingTail
        label.textAlignment = effectiveUserInterfaceLayoutDirection == .rightToLeft ? .right : .left
        label.textContainer.maximumNumberOfLines = 3
        label.text = ""
        label.isScrollEnabled = false
        label.isEditable = false
        label.isSelectable = false
        label.textContainerInset = .zero
        label.textContainer.lineFragmentPadding = 0
        label.isUserInteractionEnabled = false
        label.backgroundColor = .clear
        return label
    }()

    lazy var relativeTimeAgoLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.font = WMFFont.for(.boldFootnote, compatibleWith: traitCollection)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 1
        label.textAlignment = effectiveUserInterfaceLayoutDirection == .rightToLeft ? .left : .right
        label.text = ""
        return label
    }()

    lazy var metaLabel: UILabel = {
        let label = UILabel()
        label.font = WMFFont.for(.mediumFootnote, compatibleWith: traitCollection)
        label.adjustsFontForContentSizeCategory = true
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }()

    lazy var metaImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.adjustsImageSizeForAccessibilityContentSizeCategory = true
        imageView.setContentCompressionResistancePriority(.required, for: .vertical)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    lazy var swipeMoreActionButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(tappedMoreAction), for: .primaryActionTriggered)
        return button
    }()

    lazy var swipeMarkAsReadUnreadActionButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(tappedReadUnreadAction), for: .primaryActionTriggered)
        return button
    }()

    // MARK: - UI Elements - Stacks

    lazy var mainVerticalStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .leading
        return stackView
    }()

    lazy var internalHorizontalStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.distribution = .fill
        return stackView
    }()

    lazy var internalVerticalNotificationContentStack: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .leading
        return stackView
    }()

    lazy var metaStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    lazy var swipeActionButtonStack: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .center
        return stackView
    }()

    lazy var swipeMoreStack: StackedImageLabelView = {
        let stack = StackedImageLabelView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        let configuration = UIImage.SymbolConfiguration(weight: .semibold)
        stack.imageView.image = UIImage(systemName: "ellipsis.circle.fill", withConfiguration: configuration)
        stack.backgroundColor = WMFColor.gray500
        stack.increaseLabelTopPadding = true
        return stack
    }()

    lazy var swipeReadUnreadStack: StackedImageLabelView = {
        let stack = StackedImageLabelView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        let configuration = UIImage.SymbolConfiguration(weight: .semibold)
        stack.imageView.image = UIImage(systemName: "envelope", withConfiguration: configuration)
        stack.backgroundColor = WMFColor.green600
        return stack
    }()

    var swipeBackgroundFillView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = WMFColor.gray500
        return view
    }()

    // MARK: - UI Elements - Containers

    lazy var foregroundContentContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    lazy var backgroundActionsContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = true
        return view
    }()

    lazy var leadingContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    lazy var projectSourceContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    lazy var headerTextContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    lazy var swipeMoreActionContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = WMFColor.gray500
        view.isUserInteractionEnabled = true
        return view
    }()

    lazy var swipeMarkAsReadUnreadActionContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = WMFColor.green100
        view.isUserInteractionEnabled = true
        return view
    }()

    // MARK: - UI Elements - Helpers

    lazy var cellSeparator: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.viewModel = nil
        self.foregroundContentContainer.transform = .identity
    }

    override var isHighlighted: Bool {
        didSet {
            foregroundContentContainer.backgroundColor = isHighlighted ? theme.colors.batchSelectionBackground : theme.colors.paperBackground
        }
    }

    override var isSelected: Bool {
        didSet {
            foregroundContentContainer.backgroundColor = isSelected ? theme.colors.batchSelectionBackground : theme.colors.paperBackground
        }
    }

    func setup() {
        let topMargin: CGFloat = 13
        let edgeMargin: CGFloat = 11

        selectedBackgroundView = nil

        foregroundContentContainer.addSubview(leadingContainer)
        foregroundContentContainer.addSubview(mainVerticalStackView)

        backgroundActionsContainer.addSubview(swipeActionButtonStack)

        leadingContainer.addSubview(leadingImageView)

        headerTextContainer.addSubview(headerLabel)
        headerTextContainer.addSubview(relativeTimeAgoLabel)

        mainVerticalStackView.addArrangedSubview(headerTextContainer)
        mainVerticalStackView.addArrangedSubview(internalHorizontalStackView)

        internalHorizontalStackView.addArrangedSubview(internalVerticalNotificationContentStack)
        internalHorizontalStackView.addArrangedSubview(projectSourceContainer)

        metaStackView.addArrangedSubview(metaImageView)
        metaStackView.addArrangedSubview(HorizontalSpacerView.spacerWith(space: 3))
        metaStackView.addArrangedSubview(metaLabel)

        projectSourceContainer.addSubview(projectSourceLabel)
        projectSourceContainer.addSubview(projectSourceImage)

        let minimumSummaryHeight = (traitCollection.horizontalSizeClass == .regular) ? 40.0 : 64.0
        internalVerticalNotificationContentStack.addArrangedSubview(VerticalSpacerView.spacerWith(space: 6))
        internalVerticalNotificationContentStack.addArrangedSubview(subheaderLabel)
        internalVerticalNotificationContentStack.addArrangedSubview(VerticalSpacerView.spacerWith(space: 6))
        internalVerticalNotificationContentStack.addArrangedSubview(messageSummaryLabel)
        NSLayoutConstraint.activate([
            messageSummaryLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: minimumSummaryHeight)
        ])
        internalVerticalNotificationContentStack.addArrangedSubview(VerticalSpacerView.spacerWith(space: 3))
        internalVerticalNotificationContentStack.addArrangedSubview(metaStackView)
        internalVerticalNotificationContentStack.addArrangedSubview(VerticalSpacerView.spacerWith(space: 3))

        contentView.addSubview(swipeBackgroundFillView)
        contentView.addSubview(backgroundActionsContainer)
        contentView.addSubview(foregroundContentContainer)
        contentView.addSubview(cellSeparator)

        // Foreground and Background Container Constraints

        NSLayoutConstraint.activate([
            swipeBackgroundFillView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: NotificationsCenterCell.swipeEdgeBuffer * 2.0),
            swipeBackgroundFillView.topAnchor.constraint(equalTo: contentView.topAnchor),
            swipeBackgroundFillView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            swipeBackgroundFillView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            backgroundActionsContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            backgroundActionsContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            backgroundActionsContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            backgroundActionsContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            foregroundContentContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            foregroundContentContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            foregroundContentContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            foregroundContentContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        // Primary Hierarchy Constraints

        NSLayoutConstraint.activate([
            leadingContainer.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor),
            leadingContainer.topAnchor.constraint(equalTo: mainVerticalStackView.topAnchor),
            leadingContainer.bottomAnchor.constraint(equalTo: foregroundContentContainer.bottomAnchor),
            leadingContainer.trailingAnchor.constraint(equalTo: mainVerticalStackView.leadingAnchor),

            mainVerticalStackView.topAnchor.constraint(equalTo: foregroundContentContainer.topAnchor, constant: topMargin),
            mainVerticalStackView.bottomAnchor.constraint(equalTo: foregroundContentContainer.bottomAnchor, constant: -edgeMargin),
            mainVerticalStackView.trailingAnchor.constraint(equalTo: contentView.readableContentGuide.trailingAnchor),

            headerTextContainer.trailingAnchor.constraint(equalTo: contentView.readableContentGuide.trailingAnchor, constant: -edgeMargin),

            cellSeparator.heightAnchor.constraint(equalToConstant: 0.5),
            cellSeparator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            cellSeparator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cellSeparator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])

        // Leading Image Constraints

        NSLayoutConstraint.activate([
            leadingImageView.heightAnchor.constraint(equalToConstant: 32),
            leadingImageView.widthAnchor.constraint(equalToConstant: 32),
            leadingImageView.leadingAnchor.constraint(equalTo: leadingContainer.leadingAnchor, constant: edgeMargin),
            leadingImageView.trailingAnchor.constraint(equalTo: leadingContainer.trailingAnchor, constant: -edgeMargin),
            leadingImageView.centerYAnchor.constraint(equalTo: headerLabel.centerYAnchor, constant: topMargin/3)
        ])

        // Header label constraints

        NSLayoutConstraint.activate([
            headerLabel.leadingAnchor.constraint(equalTo: headerTextContainer.leadingAnchor),
            headerLabel.topAnchor.constraint(equalTo: headerTextContainer.topAnchor),
            headerLabel.bottomAnchor.constraint(equalTo: headerTextContainer.bottomAnchor),
            headerLabel.trailingAnchor.constraint(equalTo: relativeTimeAgoLabel.leadingAnchor),
            headerLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 50),

            relativeTimeAgoLabel.topAnchor.constraint(equalTo: headerTextContainer.topAnchor),
            relativeTimeAgoLabel.bottomAnchor.constraint(equalTo: headerTextContainer.bottomAnchor),
            relativeTimeAgoLabel.trailingAnchor.constraint(equalTo: headerTextContainer.trailingAnchor)
        ])

        // Project Source

        NSLayoutConstraint.activate([
            projectSourceContainer.widthAnchor.constraint(equalToConstant: 50),
            projectSourceContainer.trailingAnchor.constraint(equalTo: contentView.readableContentGuide.trailingAnchor, constant: -edgeMargin),

            projectSourceLabel.topAnchor.constraint(equalTo: subheaderLabel.topAnchor),
            projectSourceLabel.trailingAnchor.constraint(equalTo: projectSourceContainer.trailingAnchor),

            projectSourceImage.topAnchor.constraint(equalTo: subheaderLabel.topAnchor),
            projectSourceImage.trailingAnchor.constraint(equalTo: projectSourceContainer.trailingAnchor)
        ])

        // Meta Content

        NSLayoutConstraint.activate([
            metaImageView.widthAnchor.constraint(equalTo: metaImageView.heightAnchor)
        ])

        // Swipe Actions

        swipeActionButtonStack.addArrangedSubview(swipeMoreStack)
        swipeActionButtonStack.addArrangedSubview(swipeReadUnreadStack)

        swipeMoreStack.addSubview(swipeMoreActionButton)
        swipeReadUnreadStack.addSubview(swipeMarkAsReadUnreadActionButton)

        NSLayoutConstraint.activate([
            swipeActionButtonStack.topAnchor.constraint(equalTo: backgroundActionsContainer.topAnchor),
            swipeActionButtonStack.bottomAnchor.constraint(equalTo: backgroundActionsContainer.bottomAnchor),
            swipeActionButtonStack.trailingAnchor.constraint(equalTo: backgroundActionsContainer.trailingAnchor),
            swipeActionButtonStack.widthAnchor.constraint(equalToConstant: 200),

            swipeMoreActionButton.topAnchor.constraint(equalTo: swipeMoreStack.topAnchor),
            swipeMoreActionButton.bottomAnchor.constraint(equalTo: swipeMoreStack.bottomAnchor),
            swipeMoreActionButton.leadingAnchor.constraint(equalTo: swipeMoreStack.leadingAnchor),
            swipeMoreActionButton.trailingAnchor.constraint(equalTo: swipeMoreStack.trailingAnchor),

            swipeMarkAsReadUnreadActionButton.topAnchor.constraint(equalTo: swipeReadUnreadStack.topAnchor),
            swipeMarkAsReadUnreadActionButton.bottomAnchor.constraint(equalTo: swipeReadUnreadStack.bottomAnchor),
            swipeMarkAsReadUnreadActionButton.leadingAnchor.constraint(equalTo: swipeReadUnreadStack.leadingAnchor),
            swipeMarkAsReadUnreadActionButton.trailingAnchor.constraint(equalTo: swipeReadUnreadStack.trailingAnchor),

            swipeMoreStack.heightAnchor.constraint(equalTo: contentView.heightAnchor),
            swipeReadUnreadStack.heightAnchor.constraint(equalTo: contentView.heightAnchor)
        ])
    }

    // MARK: - Public

    fileprivate func setupAccessibility(_ viewModel: NotificationsCenterCellViewModel) {
        accessibilityLabel = viewModel.accessibilityText
        isAccessibilityElement = true
        
        if !viewModel.displayState.isEditing {
            let moreActionAccessibilityLabel = WMFLocalizedString("notifications-center-more-action-accessibility-label", value: "More", comment: "Acessibility label for the More custom action")
            let moreActionAccessibilityActionLabel = viewModel.isRead ? CommonStrings.notificationsCenterMarkAsUnread : CommonStrings.notificationsCenterMarkAsRead
            let moreAction = UIAccessibilityCustomAction(name: moreActionAccessibilityLabel, target: self, selector: #selector(tappedMoreAction))
            let markasReadorUnreadAction = UIAccessibilityCustomAction(name: moreActionAccessibilityActionLabel, target: self, selector: #selector(tappedReadUnreadAction))
    
            accessibilityCustomActions = [moreAction, markasReadorUnreadAction]
        } else {
            accessibilityCustomActions =  nil
        }
    }
    
    func configure(viewModel: NotificationsCenterCellViewModel, theme: Theme) {
        self.viewModel = viewModel
        self.theme = theme

        updateCellStyle(forDisplayState: viewModel.displayState)
        updateLabels(forViewModel: viewModel)
        updateProject(forViewModel: viewModel)
        updateMetaContent(forViewModel: viewModel)
        setupAccessibility(viewModel)
    }
    
    func configure(theme: Theme) {
        guard let viewModel = viewModel else {
            return
        }
        
        configure(viewModel: viewModel, theme: theme)
    }
}

// MARK: - Private

private extension NotificationsCenterCell {
    
    func updateColors(forDisplayState displayState: NotificationsCenterCellDisplayState) {
        guard let notificationType = viewModel?.notificationType else {
            return
        }

        let cellStyle = NotificationsCenterCellStyle(theme: theme, traitCollection: traitCollection, notificationType: notificationType)

        // Colors

        foregroundContentContainer.backgroundColor = isHighlighted || isSelected || displayState.isSelected ? theme.colors.batchSelectionBackground : theme.colors.paperBackground
        cellSeparator.backgroundColor = cellStyle.cellSeparatorColor

        let textColor = cellStyle.textColor(displayState)

        headerLabel.textColor = textColor
        subheaderLabel.textColor = textColor
        messageSummaryLabel.textColor = textColor
        relativeTimeAgoLabel.textColor = textColor
        metaImageView.tintColor = textColor
        metaLabel.textColor = textColor
        projectSourceLabel.label.textColor = textColor
        projectSourceLabel.layer.borderColor = textColor.cgColor
        projectSourceImage.tintColor = textColor
    }

    func updateCellStyle(forDisplayState displayState: NotificationsCenterCellDisplayState) {
        guard let notificationType = viewModel?.notificationType else {
            return
        }

        let cellStyle = NotificationsCenterCellStyle(theme: theme, traitCollection: traitCollection, notificationType: notificationType)
        
        updateColors(forDisplayState: displayState)

        // Fonts

        headerLabel.font = cellStyle.headerFont(displayState)
        subheaderLabel.font = cellStyle.subheaderFont(displayState)
        messageSummaryLabel.font = cellStyle.messageFont
        relativeTimeAgoLabel.font = cellStyle.relativeTimeAgoFont(displayState)
        metaLabel.font = cellStyle.metadataFont(displayState)
        projectSourceLabel.label.font = cellStyle.projectSourceFont

        // Image

        leadingImageView.backgroundColor = cellStyle.leadingImageBackgroundColor(displayState)
        leadingImageView.imageView.image = cellStyle.leadingImage(displayState)
        leadingImageView.imageView.tintColor = cellStyle.leadingImageTintColor
        leadingImageView.layer.borderColor = cellStyle.leadingImageBorderColor(displayState).cgColor
    }

    func updateLabels(forViewModel viewModel: NotificationsCenterCellViewModel) {
        headerLabel.text = viewModel.headerText
        subheaderLabel.text = viewModel.subheaderText
        let messageSummaryText = viewModel.bodyText ?? ""
        messageSummaryLabel.text = messageSummaryText.isEmpty ? " " : viewModel.bodyText
        let trimmedSummary = messageSummaryLabel.text.replacingOccurrences(of: "^\\s*", with: "", options: .regularExpression)
        messageSummaryLabel.text = trimmedSummary
        relativeTimeAgoLabel.text = viewModel.dateText
        swipeMoreStack.label.text = WMFLocalizedString("notifications-center-swipe-more", value: "More", comment: "Button text for the Notifications Center 'More' swipe action.")
        swipeReadUnreadStack.label.text = viewModel.isRead
        ? CommonStrings.notificationsCenterMarkAsUnreadSwipe
        : CommonStrings.notificationsCenterMarkAsReadSwipe
    }

    func updateProject(forViewModel viewModel: NotificationsCenterCellViewModel) {

        // Show or hide project source label and image
        if let projectText = viewModel.projectText {
            projectSourceLabel.label.text = projectText
            projectSourceLabel.isHidden = false
            projectSourceImage.isHidden = true
        } else if let projectIconName = viewModel.projectIconName {
            projectSourceImage.image = UIImage(named: projectIconName)
            projectSourceLabel.isHidden = true
            projectSourceImage.isHidden = false
        }
    }

    func updateMetaContent(forViewModel viewModel: NotificationsCenterCellViewModel) {
        let footerText = viewModel.footerText ?? ""
        metaLabel.text = footerText.isEmpty ? " " : viewModel.footerText

        guard let footerIconType = viewModel.footerIconType else {
            metaImageView.image = nil
            return
        }

        let image: UIImage?
        switch footerIconType {
        case .custom(let iconName):
            image = UIImage(named: iconName)
        case .system(let iconName):
            image = UIImage(systemName: iconName)
        }

        metaImageView.image = image
    }
    
    @objc func tappedMoreAction() {
        delegate?.userDidTapMoreActionForCell(self)
    }

    @objc func tappedReadUnreadAction() {
        delegate?.userDidTapMarkAsReadUnreadActionForCell(self)
        UIAccessibility.post(notification: .screenChanged, argument: nil)
    }
}

import UIKit

protocol NotificationsCenterCellDelegate: AnyObject {
    func userDidTapSecondaryActionForCell(_ cell: NotificationsCenterCell)
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
        insetLabel.label.font = UIFont.wmf_font(.caption1, compatibleWithTraitCollection: traitCollection)
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
        imageView.image = UIImage(named: "notifications-project-commons")
        imageView.contentMode = .scaleAspectFit

        imageView.isHidden = true

        return imageView
    }()

    lazy var headerLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.font = UIFont.wmf_font(.headline, compatibleWithTraitCollection: traitCollection)
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = effectiveUserInterfaceLayoutDirection == .rightToLeft ? .right : .left
        label.numberOfLines = 1
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.text = ""
        label.isUserInteractionEnabled = true
        return label
    }()
    
    lazy var headerLabelTapGestureRecognizer: UITapGestureRecognizer = {
        let tap = UITapGestureRecognizer(target: self, action: #selector(tappedHeaderLabel))
        headerLabel.addGestureRecognizer(tap)
        return tap
    }()

    lazy var subheaderLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.font = UIFont.wmf_font(.subheadline, compatibleWithTraitCollection: traitCollection)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 1
        label.textAlignment = effectiveUserInterfaceLayoutDirection == .rightToLeft ? .right : .left
        label.text = ""
        return label
    }()

    lazy var messageSummaryLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.font = UIFont.wmf_font(.body, compatibleWithTraitCollection: traitCollection)
        label.adjustsFontForContentSizeCategory = true
        label.lineBreakMode = .byTruncatingTail
        label.textAlignment = .left
        label.numberOfLines = 1
        label.text = ""
        return label
    }()

    lazy var relativeTimeAgoLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.font = UIFont.wmf_font(.boldFootnote, compatibleWithTraitCollection: traitCollection)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 1
        label.textAlignment = effectiveUserInterfaceLayoutDirection == .rightToLeft ? .left : .right
        label.text = ""
        return label
    }()

    lazy var metaActionButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.numberOfLines = 1
        button.adjustsImageSizeForAccessibilityContentSizeCategory = true
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.titleLabel?.font = UIFont.wmf_font(.mediumFootnote, compatibleWithTraitCollection: traitCollection)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: effectiveUserInterfaceLayoutDirection == .leftToRight ? 5 : -5, bottom: 0, right: effectiveUserInterfaceLayoutDirection == .leftToRight ? -5 : 5)
        button.isUserInteractionEnabled = false
        return button
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

    lazy var swipeMoreStack: StackedImageLabelView = {
        let stack = StackedImageLabelView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        let configuration = UIImage.SymbolConfiguration(weight: .bold)
        stack.imageView.image = UIImage(systemName: "ellipsis.circle.fill", withConfiguration: configuration)
        stack.backgroundColor = .base30
        stack.increaseLabelTopPadding = true
        return stack
    }()

    lazy var swipeReadUnreadStack: StackedImageLabelView = {
        let stack = StackedImageLabelView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        let configuration = UIImage.SymbolConfiguration(weight: .bold)
        stack.imageView.image = UIImage(systemName: "envelope", withConfiguration: configuration)
        stack.backgroundColor = .green50
        return stack
    }()

    // MARK - UI Elements - Stacks

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

    lazy var swipeActionButtonStack: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .center
        return stackView
    }()

    var swipeBackgroundFillView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .base30
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
        view.backgroundColor = .base30
        view.isUserInteractionEnabled = true
        return view
    }()

    lazy var swipeMarkAsReadUnreadActionContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .green50
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

    func setup() {
        let topMargin: CGFloat = 13
        let edgeMargin: CGFloat = 11

        selectedBackgroundView = UIView()

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

        projectSourceContainer.addSubview(projectSourceLabel)
        projectSourceContainer.addSubview(projectSourceImage)

        internalVerticalNotificationContentStack.addArrangedSubview(VerticalSpacerView.spacerWith(space: 3))
        internalVerticalNotificationContentStack.addArrangedSubview(subheaderLabel)
        internalVerticalNotificationContentStack.addArrangedSubview(VerticalSpacerView.spacerWith(space: 3))
        internalVerticalNotificationContentStack.addArrangedSubview(messageSummaryLabel)
        internalVerticalNotificationContentStack.addArrangedSubview(VerticalSpacerView.spacerWith(space: 10))
        internalVerticalNotificationContentStack.addArrangedSubview(metaActionButton)
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
            foregroundContentContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])

        // Primary Hierarchy Constraints

        NSLayoutConstraint.activate([
            leadingContainer.leadingAnchor.constraint(equalTo: foregroundContentContainer.leadingAnchor),
            leadingContainer.topAnchor.constraint(equalTo: mainVerticalStackView.topAnchor),
            leadingContainer.bottomAnchor.constraint(equalTo: foregroundContentContainer.bottomAnchor),
            leadingContainer.trailingAnchor.constraint(equalTo: mainVerticalStackView.leadingAnchor),

            mainVerticalStackView.topAnchor.constraint(equalTo: foregroundContentContainer.topAnchor, constant: topMargin),
            mainVerticalStackView.bottomAnchor.constraint(equalTo: foregroundContentContainer.bottomAnchor, constant: -edgeMargin),
            mainVerticalStackView.trailingAnchor.constraint(equalTo: foregroundContentContainer.trailingAnchor),

            headerTextContainer.trailingAnchor.constraint(equalTo: foregroundContentContainer.trailingAnchor, constant: -edgeMargin),

            cellSeparator.heightAnchor.constraint(equalToConstant: 0.5),
            cellSeparator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            cellSeparator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cellSeparator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
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
            projectSourceContainer.trailingAnchor.constraint(equalTo: foregroundContentContainer.trailingAnchor, constant: -edgeMargin),

            projectSourceLabel.topAnchor.constraint(equalTo: subheaderLabel.topAnchor),
            projectSourceLabel.trailingAnchor.constraint(equalTo: projectSourceContainer.trailingAnchor),

            projectSourceImage.topAnchor.constraint(equalTo: subheaderLabel.topAnchor),
            projectSourceImage.trailingAnchor.constraint(equalTo: projectSourceContainer.trailingAnchor),
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
            swipeReadUnreadStack.heightAnchor.constraint(equalTo: contentView.heightAnchor),
        ])
    }

    // MARK: - Public

    func configure(viewModel: NotificationsCenterCellViewModel, theme: Theme) {
        self.viewModel = viewModel
        self.theme = theme

        updateCellStyle(forDisplayState: viewModel.displayState)
        updateLabels(forViewModel: viewModel)
        updateProject(forViewModel: viewModel)
        updateMetaButton(forViewModel: viewModel)
        
        headerLabelTapGestureRecognizer.isEnabled = viewModel.shouldAllowSecondaryTapAction
    }
    
    func configure(theme: Theme) {
        guard let viewModel = viewModel else {
            return
        }
        
        configure(viewModel: viewModel, theme: theme)
    }
}

//MARK: - Private

private extension NotificationsCenterCell {

    func updateCellStyle(forDisplayState displayState: NotificationsCenterCellDisplayState) {
        guard let notificationType = viewModel?.notificationType else {
            return
        }

        let cellStyle = NotificationsCenterCellStyle(theme: theme, traitCollection: traitCollection, notificationType: notificationType)

        // Colors

        foregroundContentContainer.backgroundColor = theme.colors.paperBackground
        cellSeparator.backgroundColor = cellStyle.cellSeparatorColor

        headerLabel.textColor = cellStyle.headerTextColor(displayState)
        subheaderLabel.textColor = cellStyle.subheaderTextColor(displayState)
        messageSummaryLabel.textColor = cellStyle.messageTextColor
        relativeTimeAgoLabel.textColor = cellStyle.relativeTimeAgoColor
        metaActionButton.setTitleColor(cellStyle.metadataTextColor, for: .normal)
        metaActionButton.imageView?.tintColor = cellStyle.metadataTextColor
        projectSourceLabel.label.textColor = cellStyle.projectSourceColor
        projectSourceLabel.layer.borderColor = cellStyle.projectSourceColor.cgColor
        projectSourceImage.tintColor = cellStyle.projectSourceColor

        selectedBackgroundView?.backgroundColor = cellStyle.selectedCellBackgroundColor

        // Fonts

        headerLabel.font = cellStyle.headerFont(displayState)
        subheaderLabel.font = cellStyle.subheaderFont(displayState)
        messageSummaryLabel.font = cellStyle.messageFont
        relativeTimeAgoLabel.font = cellStyle.relativeTimeAgoFont(displayState)
        metaActionButton.titleLabel?.font = cellStyle.metadataFont(displayState)
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
        relativeTimeAgoLabel.text = viewModel.dateText
        swipeMoreStack.label.text = WMFLocalizedString("notifications-center-swipe-more", value: "More", comment: "Button text for the Notifications Center 'More' swipe action.")
        swipeReadUnreadStack.label.text = viewModel.isRead
            ? WMFLocalizedString("notifications-center-swipe-mark-as-unread", value: "Mark as unread", comment: "Button text in Notifications Center swipe actions to mark a notification as unread.")
            : WMFLocalizedString("notifications-center-swipe-mark-as-read", value: "Mark as read", comment: "Button text in Notifications Center swipe actions to mark a notification as read.")
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

    func updateMetaButton(forViewModel viewModel: NotificationsCenterCellViewModel) {
        let footerText = viewModel.footerText ?? ""
        metaActionButton.setTitle(footerText.isEmpty ? " " : viewModel.footerText, for: .normal)

        guard let footerIconType = viewModel.footerIconType else {
            metaActionButton.setImage(nil, for: .normal)
            return
        }

        let image: UIImage?
        switch footerIconType {
        case .custom(let iconName):
            image = UIImage(named: iconName)
        case .system(let iconName):
            image = UIImage(systemName: iconName)
        }

        metaActionButton.setImage(image, for: .normal)
    }
    
    @objc func tappedHeaderLabel() {
        delegate?.userDidTapSecondaryActionForCell(self)
    }

    @objc func tappedMoreAction() {
        delegate?.userDidTapMoreActionForCell(self)
    }

    @objc func tappedReadUnreadAction() {
        delegate?.userDidTapMarkAsReadUnreadActionForCell(self)
    }

}

import UIKit

protocol NotificationsCenterCellDelegate: AnyObject {
	func userDidTapSecondaryActionForCellIdentifier(id: String)
}

final class NotificationsCenterCell: UICollectionViewCell {

	// MARK: - Properties

	static let reuseIdentifier = "NotificationsCenterCell"

	fileprivate var theme: Theme = .light
	fileprivate weak var viewModel: NotificationsCenterCellViewModel?

	// MARK: - UI Elements

	lazy var leadingImageView: RoundedImageView = {
		if #available(iOS 13.0, *) {
			let view = RoundedImageView()
			view.translatesAutoresizingMaskIntoConstraints = false
			view.imageView.contentMode = .scaleAspectFit
			view.layer.borderWidth = 2
			view.layer.borderColor = UIColor.clear.cgColor
			view.insets = UIEdgeInsets(top: 6, left: 6, bottom: -6, right: -6)
			return view
		} else {
			fatalError()
		}
	}()

	lazy var projectSourceLabel: InsetLabelView = {
		let label = InsetLabelView()

		label.translatesAutoresizingMaskIntoConstraints = false
		label.label.setContentCompressionResistancePriority(.required, for: .vertical)
		label.label.font = UIFont.wmf_font(.caption1, compatibleWithTraitCollection: traitCollection)
		label.label.adjustsFontForContentSizeCategory = true
		label.label.numberOfLines = 1
		label.label.text = "EN"
		label.label.textAlignment = .center

		label.layer.cornerRadius = 3
		label.layer.borderWidth = 1
		label.layer.borderColor = UIColor.black.cgColor

		label.insets = UIEdgeInsets(top: 4, left: 4, bottom: -4, right: -4)

		return label
	}()

	lazy var projectSourceImage: UIImageView = {
		let imageView = UIImageView()
		imageView.translatesAutoresizingMaskIntoConstraints = false
		if #available(iOS 13.0, *) {
			let symbolConfiguration = UIImage.SymbolConfiguration(weight: .bold)
			imageView.image = UIImage(systemName: "checkmark", withConfiguration: symbolConfiguration)
		}
		imageView.contentMode = .scaleAspectFit
		return imageView
	}()

	lazy var headerLabel: UILabel = {
		let label = UILabel()
		label.translatesAutoresizingMaskIntoConstraints = false
		label.setContentCompressionResistancePriority(.required, for: .vertical)
		label.font = UIFont.wmf_font(.headline, compatibleWithTraitCollection: traitCollection)
		label.adjustsFontForContentSizeCategory = true
		label.textAlignment = .left
		label.numberOfLines = 1
		label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
		label.setContentHuggingPriority(.required, for: .horizontal)
		label.text = ""
		return label
	}()

	lazy var subheaderLabel: UILabel = {
		let label = UILabel()
		label.translatesAutoresizingMaskIntoConstraints = false
		label.setContentCompressionResistancePriority(.required, for: .vertical)
		label.font = UIFont.wmf_font(.subheadline, compatibleWithTraitCollection: traitCollection)
		label.adjustsFontForContentSizeCategory = true
		label.numberOfLines = 1
		label.textAlignment = .left
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
		label.font = UIFont.wmf_font(DynamicTextStyle.boldFootnote, compatibleWithTraitCollection: traitCollection)
		label.adjustsFontForContentSizeCategory = true
		label.numberOfLines = 1
		label.textAlignment = .right
		label.text = ""
		return label
	}()

	lazy var metaActionButton: UIButton = {
		if #available(iOS 13.0, *) {
			let button = UIButton()
			button.translatesAutoresizingMaskIntoConstraints = false
			button.setImage(UIImage(systemName: "text.book.closed.fill"), for: .normal)
			button.titleLabel?.numberOfLines = 1
			button.titleLabel?.textAlignment = .left
			button.adjustsImageSizeForAccessibilityContentSizeCategory = true
			button.titleLabel?.adjustsFontForContentSizeCategory = true
			button.titleLabel?.font = UIFont.wmf_font(DynamicTextStyle.mediumFootnote, compatibleWithTraitCollection: traitCollection)
			button.setTitle("Article: Wikipedia", for: .normal)
			button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: -5)
			button.isUserInteractionEnabled = false
			return button
		} else {
			fatalError()
		}
	}()

	lazy var projectImageView: UIImageView = {
		let imageView = UIImageView()
		imageView.translatesAutoresizingMaskIntoConstraints = false
		return imageView
	}()

	lazy var wikipediaLanguageLabel: UILabel = {
		let label = UILabel()
		label.translatesAutoresizingMaskIntoConstraints = false
		label.setContentCompressionResistancePriority(.required, for: .vertical)
		label.font = UIFont.wmf_font(DynamicTextStyle.caption2, compatibleWithTraitCollection: traitCollection)
		label.adjustsFontForContentSizeCategory = true
		label.numberOfLines = 1
		label.text = ""
		return label
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

	// MARK: - UI Elements - Containers

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
	}

	func setup() {
		let edgeMargin: CGFloat = 11

		selectedBackgroundView = UIView()

		contentView.addSubview(leadingContainer)
		contentView.addSubview(mainVerticalStackView)
		contentView.addSubview(cellSeparator)

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

		// Primary Hierarchy Constraints

		NSLayoutConstraint.activate([
			leadingContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
			leadingContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
			leadingContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
			leadingContainer.trailingAnchor.constraint(equalTo: mainVerticalStackView.leadingAnchor),

			mainVerticalStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: edgeMargin),
			mainVerticalStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -edgeMargin),
			mainVerticalStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

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
			leadingImageView.topAnchor.constraint(equalTo: leadingContainer.topAnchor, constant: edgeMargin),
		])

		// Header label constraints

		NSLayoutConstraint.activate([
			headerLabel.leadingAnchor.constraint(equalTo: headerTextContainer.leadingAnchor),
			headerLabel.topAnchor.constraint(equalTo: headerTextContainer.topAnchor),
			headerLabel.bottomAnchor.constraint(equalTo: headerTextContainer.bottomAnchor),
			headerLabel.trailingAnchor.constraint(equalTo: relativeTimeAgoLabel.leadingAnchor),

			relativeTimeAgoLabel.topAnchor.constraint(equalTo: headerTextContainer.topAnchor),
			relativeTimeAgoLabel.bottomAnchor.constraint(equalTo: headerTextContainer.bottomAnchor),
			relativeTimeAgoLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -edgeMargin)
		])

		// Project Source

		NSLayoutConstraint.activate([
			projectSourceContainer.widthAnchor.constraint(equalToConstant: 50),
			projectSourceContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -edgeMargin),

			projectSourceLabel.topAnchor.constraint(greaterThanOrEqualTo: projectSourceContainer.topAnchor),
			projectSourceLabel.trailingAnchor.constraint(equalTo: relativeTimeAgoLabel.trailingAnchor),
			projectSourceLabel.centerYAnchor.constraint(greaterThanOrEqualTo: contentView.centerYAnchor),

			projectSourceImage.topAnchor.constraint(greaterThanOrEqualTo: projectSourceContainer.topAnchor),
			projectSourceImage.trailingAnchor.constraint(equalTo: relativeTimeAgoLabel.trailingAnchor),
			projectSourceImage.centerYAnchor.constraint(greaterThanOrEqualTo: contentView.centerYAnchor),
		])

		wmf_configureSubviewsForDynamicType()
	}

	// MARK: - Public

	func configure(viewModel: NotificationsCenterCellViewModel, theme: Theme) {
		self.viewModel = viewModel
		self.theme = theme

		headerLabel.text = viewModel.notification.agentName
		subheaderLabel.text = viewModel.notification.messageHeader
		messageSummaryLabel.text = "This is the notification's body text" // from viewModel
		relativeTimeAgoLabel.text = "12 minutes ago" // from viewModel

		updateCellStyle(forDisplayState: viewModel.displayState)

		// Show or hide project source label and image
		// ...
	}

	fileprivate func updateCellStyle(forDisplayState displayState: NotificationsCenterCellDisplayState) {
		guard let category = viewModel?.notification.category else {
			return
		}

		// let displayState = NotificationsCenterCellDisplayState.allCases.randomElement()!		
		let cellStyle = NotificationsCenterCellStyle(theme: theme, traitCollection: traitCollection, category: category)

		// Colors

		cellSeparator.backgroundColor = cellStyle.cellSeparatorColor

		headerLabel.textColor = cellStyle.headerTextColor(displayState)
		subheaderLabel.textColor = cellStyle.subheaderTextColor(displayState)
		messageSummaryLabel.textColor = cellStyle.messageTextColor(displayState)
		relativeTimeAgoLabel.textColor = cellStyle.relativeTimeAgoColor(displayState)
		metaActionButton.setTitleColor(cellStyle.metadataTextColor, for: .normal)
		metaActionButton.imageView?.tintColor = cellStyle.metadataTextColor
		projectSourceLabel.label.textColor = cellStyle.projectSourceColor(displayState)
		projectSourceLabel.layer.borderColor = cellStyle.projectSourceColor(displayState).cgColor
		projectSourceImage.tintColor = cellStyle.projectSourceColor(displayState)

		selectedBackgroundView?.backgroundColor = cellStyle.selectedCellBackgroundColor

		// Fonts

		headerLabel.font = cellStyle.headerFont(displayState)
		subheaderLabel.font = cellStyle.subheaderFont(displayState)
		messageSummaryLabel.font = cellStyle.messageFont(displayState)
		relativeTimeAgoLabel.font = cellStyle.relativeTimeAgoFont(displayState)
		metaActionButton.titleLabel?.font = cellStyle.metadataFont(displayState)
		projectSourceLabel.label.font = cellStyle.projectSourceFont(displayState)

		// Image

		leadingImageView.backgroundColor = cellStyle.leadingImageBackgroundColor(displayState)
		leadingImageView.imageView.image = cellStyle.leadingImage(displayState)
		leadingImageView.imageView.tintColor = cellStyle.leadingImageTintColor
		leadingImageView.layer.borderColor = cellStyle.leadingImageBorderColor(displayState).cgColor
	}

}

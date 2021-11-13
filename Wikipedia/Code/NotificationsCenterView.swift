import UIKit

final class NotificationsCenterView: SetupView {

    // MARK: - Nested Types

    enum EmptyOverlayStrings {
        static let noUnreadMessages = WMFLocalizedString("notifications-center-empty-no-unread-messages", value: "You have no unread messages", comment: "Text displayed when no Notifications Center notifications are available.")
        static let notSubscribed = WMFLocalizedString("notifications-center-empty-not-subscribed", value: "You are not currently subscribed to any Wikipedia Notifications", comment: "Text displayed when user has not subscribed to any Wikipedia notifications.")
        static let checkingForNotifications = WMFLocalizedString("notifications-center-empty-checking-for-notifications", value: "Checking for notifications...", comment: "Text displayed when Notifications Center is checking for notifications.")
    }

    // MARK: - Properties

	lazy var collectionView: UICollectionView = {
		let collectionView = UICollectionView(frame: .zero, collectionViewLayout: tableStyleLayout)
		collectionView.register(NotificationsCenterCell.self, forCellWithReuseIdentifier: NotificationsCenterCell.reuseIdentifier)
		collectionView.alwaysBounceVertical = true
		collectionView.translatesAutoresizingMaskIntoConstraints = false
		return collectionView
	}()

	private lazy var tableStyleLayout: UICollectionViewLayout = {
        let estimatedHeightDimension = NSCollectionLayoutDimension.estimated(120)
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),heightDimension: estimatedHeightDimension)
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),heightDimension: estimatedHeightDimension)
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        let layout = UICollectionViewCompositionalLayout(section: section)
        return layout
	}()

    private lazy var emptyScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.isUserInteractionEnabled = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.isHidden = true
        return scrollView
    }()

    private lazy var emptyOverlayStack: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        stackView.alignment = .center
        stackView.spacing = 15
        return stackView
    }()

    private lazy var emptyStateImageView: UIImageView = {
        let image = UIImage(named: "notifications-center-empty")
        let imageView = UIImageView(image: image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private lazy var emptyOverlayHeaderLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.wmf_font(.mediumBody, compatibleWithTraitCollection: traitCollection)
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var emptyOverlaySubheaderLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.wmf_font(.subheadline, compatibleWithTraitCollection: traitCollection)
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    // MARK: - Lifecycle

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            emptyOverlayHeaderLabel.font = UIFont.wmf_font(.mediumBody, compatibleWithTraitCollection: traitCollection)
            emptyOverlaySubheaderLabel.font = UIFont.wmf_font(.subheadline, compatibleWithTraitCollection: traitCollection)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // If the stack view content is approaching or greater than the visible view's height, allow scrolling to read all content
        emptyScrollView.alwaysBounceVertical = emptyOverlayStack.bounds.height > emptyScrollView.bounds.height - 100
    }

    // MARK: - Setup

    override func setup() {
        backgroundColor = .white
        wmf_addSubviewWithConstraintsToEdges(collectionView)
        wmf_addSubviewWithConstraintsToEdges(emptyScrollView)

        emptyOverlayStack.addArrangedSubview(emptyStateImageView)
        emptyOverlayStack.addArrangedSubview(emptyOverlayHeaderLabel)
        emptyOverlayStack.addArrangedSubview(emptyOverlaySubheaderLabel)

        emptyScrollView.addSubview(emptyOverlayStack)

        NSLayoutConstraint.activate([
            emptyScrollView.contentLayoutGuide.widthAnchor.constraint(equalTo: emptyScrollView.frameLayoutGuide.widthAnchor),
            emptyScrollView.contentLayoutGuide.heightAnchor.constraint(greaterThanOrEqualTo: emptyScrollView.frameLayoutGuide.heightAnchor),

            emptyOverlayStack.centerXAnchor.constraint(equalTo: emptyScrollView.contentLayoutGuide.centerXAnchor),
            emptyOverlayStack.centerYAnchor.constraint(equalTo: emptyScrollView.contentLayoutGuide.centerYAnchor),

            emptyOverlayStack.topAnchor.constraint(greaterThanOrEqualTo: emptyScrollView.contentLayoutGuide.topAnchor, constant: 100),
            emptyOverlayStack.leadingAnchor.constraint(greaterThanOrEqualTo: emptyScrollView.contentLayoutGuide.leadingAnchor, constant: 25),
            emptyOverlayStack.trailingAnchor.constraint(lessThanOrEqualTo: emptyScrollView.contentLayoutGuide.trailingAnchor, constant: -25),
            emptyOverlayStack.bottomAnchor.constraint(lessThanOrEqualTo: emptyScrollView.contentLayoutGuide.bottomAnchor, constant: -100),

            emptyStateImageView.heightAnchor.constraint(equalToConstant: 185),
            emptyStateImageView.widthAnchor.constraint(equalToConstant: 185),

            emptyOverlayHeaderLabel.widthAnchor.constraint(equalTo: emptyOverlayStack.widthAnchor, multiplier: 3/4),
            emptyOverlaySubheaderLabel.widthAnchor.constraint(equalTo: emptyOverlayStack.widthAnchor, multiplier: 4/5)
        ])
    }

    // MARK: - Public

    func updateEmptyOverlay(visible: Bool, headerText: String = "", subheaderText: String = "") {
        emptyScrollView.isHidden = !visible
        emptyScrollView.isUserInteractionEnabled = visible
        emptyOverlayHeaderLabel.text = headerText
        emptyOverlaySubheaderLabel.text = subheaderText
    }

}

extension NotificationsCenterView: Themeable {

    func apply(theme: Theme) {
        backgroundColor = theme.colors.paperBackground
        collectionView.backgroundColor = theme.colors.paperBackground
        emptyOverlayHeaderLabel.textColor = theme.colors.primaryText
        emptyOverlaySubheaderLabel.textColor = theme.colors.primaryText
    }

}

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
		// collectionView.allowsMultipleSelection = true
		return collectionView
	}()

	private lazy var tableStyleLayout: UICollectionViewLayout = {
        let estimatedHeightDimension = NSCollectionLayoutDimension.estimated(130)
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),heightDimension: estimatedHeightDimension)
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),heightDimension: estimatedHeightDimension)
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        let layout = UICollectionViewCompositionalLayout(section: section)
        return layout
	}()

    private lazy var emptyOverlayStack: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        stackView.alignment = .center
        stackView.spacing = 15
        stackView.isHidden = true        
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
        label.font = UIFont.wmf_font(.mediumBody)
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var emptyOverlaySubheaderLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.wmf_font(.subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    // MARK: - Setup

    override func setup() {
        backgroundColor = .white
        wmf_addSubviewWithConstraintsToEdges(collectionView)

        emptyOverlayStack.addArrangedSubview(emptyStateImageView)
        emptyOverlayStack.addArrangedSubview(emptyOverlayHeaderLabel)
        emptyOverlayStack.addArrangedSubview(emptyOverlaySubheaderLabel)

        addSubview(emptyOverlayStack)
        NSLayoutConstraint.activate([
            emptyOverlayHeaderLabel.widthAnchor.constraint(equalTo: emptyStateImageView.widthAnchor, constant: 60),
            emptyOverlayHeaderLabel.centerXAnchor.constraint(equalTo: emptyStateImageView.centerXAnchor),
            emptyOverlaySubheaderLabel.widthAnchor.constraint(equalTo: emptyOverlayHeaderLabel.widthAnchor, constant: 20),

            emptyStateImageView.heightAnchor.constraint(equalToConstant: 185),
            emptyStateImageView.widthAnchor.constraint(equalTo: emptyStateImageView.heightAnchor),

            emptyOverlayStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            emptyOverlayStack.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -5)
        ])
    }

    // MARK: - Public

    func updateEmptyOverlay(visible: Bool, headerString: String = "", subheaderText: String = "") {
        emptyOverlayStack.isHidden = !visible
        emptyOverlayHeaderLabel.text = headerString
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

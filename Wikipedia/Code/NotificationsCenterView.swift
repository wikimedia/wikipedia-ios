import WMFComponents

final class NotificationsCenterView: SetupView {

    // MARK: - Nested Types

    enum EmptyOverlayStrings {
        static let noUnreadMessages = WMFLocalizedString("notifications-center-empty-no-messages", value: "You have no messages", comment: "Text displayed when no Notifications Center notifications are available.")
        static let notSubscribed = WMFLocalizedString("notifications-center-empty-not-subscribed", value: "You are not currently subscribed to any Wikipedia Notifications", comment: "Text displayed when user has not subscribed to any Wikipedia notifications.")
        static let checkingForNotifications = WMFLocalizedString("notifications-center-empty-checking-for-notifications", value: "Checking for notifications...", comment: "Text displayed when Notifications Center is checking for notifications.")
    }

    // MARK: - Properties

    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: tableStyleLayout())
        collectionView.register(NotificationsCenterCell.self, forCellWithReuseIdentifier: NotificationsCenterCell.reuseIdentifier)
        collectionView.alwaysBounceVertical = true
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.refreshControl = refreshControl
        return collectionView
    }()

    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.layer.zPosition = -100
        return refreshControl
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
        label.font = WMFFont.for(.boldCallout, compatibleWith: traitCollection)
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var emptyOverlaySubheaderLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = WMFFont.for(.subheadline, compatibleWith: traitCollection)
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isUserInteractionEnabled = true
        return label
    }()

    // MARK: - Lifecycle

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            emptyOverlayHeaderLabel.font = WMFFont.for(.boldCallout, compatibleWith: traitCollection)
            emptyOverlaySubheaderLabel.font = WMFFont.for(.subheadline, compatibleWith: traitCollection)
            calculatedCellHeight = nil
        }

        if previousTraitCollection?.horizontalSizeClass != traitCollection.horizontalSizeClass {
             calculatedCellHeight = nil
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
    
    private var subheaderTapGR: UITapGestureRecognizer?
    
    func addSubheaderTapGestureRecognizer(target: Any, action: Selector) {
        let tap = UITapGestureRecognizer(target: target, action: action)
        self.subheaderTapGR = tap
        emptyOverlaySubheaderLabel.addGestureRecognizer(tap)
    }
    
    func updateEmptyVisibility(visible: Bool) {
        emptyScrollView.isHidden = !visible
        emptyScrollView.isUserInteractionEnabled = visible
    }

    func updateEmptyContent(headerText: String = "", subheaderText: String = "", subheaderAttributedString: NSAttributedString?) {
        emptyOverlayHeaderLabel.text = headerText
        if let subheaderAttributedString = subheaderAttributedString {
            emptyOverlaySubheaderLabel.attributedText = subheaderAttributedString
            subheaderTapGR?.isEnabled = true
        } else {
            emptyOverlaySubheaderLabel.text = subheaderText
            subheaderTapGR?.isEnabled = false
        }
    }
    
    func updateCalculatedCellHeightIfNeeded() {

        guard let firstCell = collectionView.visibleCells.first else {
            return
        }

        if self.calculatedCellHeight == nil {
            let calculatedCellHeight = firstCell.frame.size.height
            self.calculatedCellHeight = calculatedCellHeight
        }
    }
    
// MARK: Private
    
    private var calculatedCellHeight: CGFloat? {
        didSet {
            if oldValue != calculatedCellHeight {
                collectionView.setCollectionViewLayout(tableStyleLayout(calculatedCellHeight: calculatedCellHeight), animated: false)
            }
        }
    }

    private func tableStyleLayout(calculatedCellHeight: CGFloat? = nil) -> UICollectionViewLayout {
        let heightDimension: NSCollectionLayoutDimension

        if let calculatedCellHeight = calculatedCellHeight {
            heightDimension = NSCollectionLayoutDimension.absolute(calculatedCellHeight)
        } else {
            heightDimension = NSCollectionLayoutDimension.estimated(150)
        }

        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),heightDimension: heightDimension)
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),heightDimension: heightDimension)
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        let layout = UICollectionViewCompositionalLayout(section: section)
        return layout
    }
}

extension NotificationsCenterView: Themeable {

    func apply(theme: Theme) {
        backgroundColor = theme.colors.paperBackground
        collectionView.backgroundColor = theme.colors.paperBackground
        refreshControl.tintColor = theme.colors.refreshControlTint
        emptyOverlayHeaderLabel.textColor = theme.colors.primaryText
        emptyOverlaySubheaderLabel.textColor = theme.colors.primaryText
    }

}

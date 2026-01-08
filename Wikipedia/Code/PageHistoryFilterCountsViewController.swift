import UIKit
import WMFComponents

protocol PageHistoryFilterCountsViewDelegate: AnyObject {
    func didDetermineFilterCountsAvailability(_ available: Bool, view: PageHistoryFilterCountsView)
}

class PageHistoryFilterCountsView: UIView {
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())

    weak var delegate: PageHistoryFilterCountsViewDelegate?
    var theme = Theme.standard

    private var counts: [Count] = []

    var editCountsGroupedByType: EditCountsGroupedByType? {
        didSet {
            counts = []
            defer {
                collectionView.reloadData()
                activityIndicator.stopAnimating()
            }
            guard let editCounts = editCountsGroupedByType else {
                delegate?.didDetermineFilterCountsAvailability(false, view: self)
                return
            }
            if let loggedInEdits = editCounts[.customLoggedIn]?.count {
                counts.append(Count(title: WMFLocalizedString("page-history-logged-in-edits", value: "logged-in", comment: "Text for view that shows many edits were made by logged-in users"), image: UIImage(named: "user-edit"), count: loggedInEdits))
            }
            if let unregisteredEdits = editCounts[.customUnregistered]?.count {
                counts.append(Count(title: WMFLocalizedString("page-history-unregistered-edits", value: "unregistered", comment: "Text for view that shows many edits were made by unregistered users"), image: WMFIcon.anonymous, count: unregisteredEdits))
            }
            if let botEdits = editCounts[.bot]?.count {
                counts.append(Count(title: WMFLocalizedString("page-history-bot-edits", value: "bot", comment: "Text for view that shows many edits were made by bots"), image: UIImage(named: "bot"), count: botEdits))
            }
            if let minorEdits = editCounts[.minor]?.count {
                counts.append(Count(title: WMFLocalizedString("page-history-minor-edits", value: "minor edits", comment: "Text for view that shows many edits were marked as minor edits"), image: UIImage(named: "m"), count: minorEdits))
            }
            countOfColumns = CGFloat(counts.count)
            delegate?.didDetermineFilterCountsAvailability(!counts.isEmpty, view: self)
        }
    }

    private struct Count {
        let title: String
        let image: UIImage?
        let count: Int
    }

    private func displayCount(_ count: Int) -> String {
        return NumberFormatter.localizedThousandsStringFromNumber(NSNumber(value: count))
    }

    private lazy var collectionViewHeightConstraint = collectionView.heightAnchor.constraint(equalToConstant: 60)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        collectionView.dataSource = self
        collectionView.register(UINib(nibName: "PageHistoryFilterCountCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: PageHistoryFilterCountCollectionViewCell.identifier)
        collectionViewHeightConstraint.isActive = true
        wmf_addSubviewWithConstraintsToEdges(collectionView)

        addActivityIndicator()
        activityIndicator.color = theme.isDark ? .white : .gray
        activityIndicator.startAnimating()

        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.sectionInset = .zero
        flowLayout.minimumLineSpacing = 0

        apply(theme: theme)
    }

    private func addActivityIndicator() {
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        insertSubview(activityIndicator, aboveSubview: collectionView)
        NSLayoutConstraint.activate([
            activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor),
            activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
    }

    private var countOfColumns: CGFloat = 4 {
        didSet {
            calculateSizes()
        }
    }

    private var columnWidth: CGFloat {
        let availableWidth = collectionView.bounds.width - flowLayout.minimumInteritemSpacing * (countOfColumns - 1) - collectionView.contentInset.left - collectionView.contentInset.right - flowLayout.sectionInset.left - flowLayout.sectionInset.right
        return floor(availableWidth / countOfColumns)
    }

    private var flowLayout: UICollectionViewFlowLayout {
        return collectionView.collectionViewLayout as! UICollectionViewFlowLayout
    }

    private lazy var placeholderCell = PageHistoryFilterCountCollectionViewCell.wmf_viewFromClassNib()!

    private func calculateSizes() {
        var height = collectionViewHeightConstraint.constant
        for (index, count) in counts.enumerated() {
            let size = placeholderCell.sizeWith(width: columnWidth, title: count.title, image: count.image, imageText: displayCount(count.count), isRightSeparatorHidden: index == counts.count - 1)
            height = max(height, size.height)
        }
        collectionViewHeightConstraint.constant = height
        flowLayout.itemSize = CGSize(width: columnWidth, height: height)
    }
}

extension PageHistoryFilterCountsView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return counts.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PageHistoryFilterCountCollectionViewCell.identifier, for: indexPath) as? PageHistoryFilterCountCollectionViewCell else {
            return UICollectionViewCell()
        }
        configure(cell, at: indexPath)
        return cell
    }

    private func configure(_ cell: PageHistoryFilterCountCollectionViewCell, at indexPath: IndexPath) {
        let count = counts[indexPath.item]
        cell.configure(with: count.title, image: count.image, imageText: displayCount(count.count), isRightSeparatorHidden: indexPath.item == counts.count - 1)
        cell.apply(theme: theme)
    }

}

extension PageHistoryFilterCountsView: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        backgroundColor = theme.colors.paperBackground
        collectionView.backgroundColor = backgroundColor
        activityIndicator.color = theme.isDark ? .white : .gray
    }
}

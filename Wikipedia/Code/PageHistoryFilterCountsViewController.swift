import UIKit

protocol PageHistoryFilterCountsViewControllerDelegate: AnyObject {
    func didDetermineFilterCountsAvailability(_ available: Bool, viewController: PageHistoryFilterCountsViewController)
}

class PageHistoryFilterCountsViewController: UIViewController {
    private let activityIndicator = UIActivityIndicatorView(style: .whiteLarge)
    private let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())

    weak var delegate: PageHistoryFilterCountsViewControllerDelegate?
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
                delegate?.didDetermineFilterCountsAvailability(false, viewController: self)
                return
            }
            if let userEdits = editCounts[.userEdits]?.count {
                counts.append(Count(title: WMFLocalizedString("page-history-user-edits", value: "user edits", comment: "Text for view that shows many edits were made by logged-in users"), image: UIImage(named: "user-edit"), count: userEdits))
            }
            if let anonEdits = editCounts[.anonymous]?.count {
                counts.append(Count(title: WMFLocalizedString("page-history-anonymous-edits", value: "anon edits", comment: "Text for view that shows many edits were made by anonymous users"), image: UIImage(named: "anon"), count: anonEdits))
            }
            if let botEdits = editCounts[.bot]?.count {
                counts.append(Count(title: WMFLocalizedString("page-history-bot-edits", value: "bot edits", comment: "Text for view that shows many edits were made by bots"), image: UIImage(named: "bot"), count: botEdits))
            }
            if let minorEdits = editCounts[.minor]?.count {
                counts.append(Count(title: WMFLocalizedString("page-history-minor-edits", value: "minor edits", comment: "Text for view that shows many edits were marked as minor edits"), image: UIImage(named: "m"), count: minorEdits))
            }
            countOfColumns = CGFloat(counts.count)
            delegate?.didDetermineFilterCountsAvailability(!counts.isEmpty, viewController: self)
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

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.dataSource = self
        collectionView.register(UINib(nibName: "PageHistoryFilterCountCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: PageHistoryFilterCountCollectionViewCell.identifier)
        collectionViewHeightConstraint.isActive = true
        view.wmf_addSubviewWithConstraintsToEdges(collectionView)

        addActivityIndicator()
        activityIndicator.style = theme.isDark ? .white : .gray
        activityIndicator.startAnimating()

        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.sectionInset = .zero
        flowLayout.minimumLineSpacing = 0

        apply(theme: theme)
    }

    private func addActivityIndicator() {
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(activityIndicator, aboveSubview: collectionView)
        NSLayoutConstraint.activate([
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in
            self.collectionView.collectionViewLayout.invalidateLayout()
            self.calculateSizes()
        })
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

extension PageHistoryFilterCountsViewController: UICollectionViewDataSource {
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

extension PageHistoryFilterCountsViewController: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        view.backgroundColor = theme.colors.paperBackground
        collectionView.backgroundColor = view.backgroundColor
        activityIndicator.style = theme.isDark ? .white : .gray
    }
}

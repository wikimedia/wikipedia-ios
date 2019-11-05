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
                return
            }
            if case let userEdits?? = editCounts[.userEdits] {
                counts.append(Count(title: WMFLocalizedString("page-history-user-edits", value: "user edits", comment: "Text for view that shows many edits were made by logged-in users"), image: UIImage(named: "user-edit")!, count: userEdits))
            }
            if case let anonEdits?? = editCounts[.anonymous] {
                counts.append(Count(title: WMFLocalizedString("page-history-anonymous-edits", value: "anonymous edits", comment: "Text for view that shows many edits were made by anonymous users"), image: UIImage(named: "anon")!, count: anonEdits))
            }
            if case let botEdits?? = editCounts[.bot] {
                counts.append(Count(title: WMFLocalizedString("page-history-bot-edits", value: "bot edits", comment: "Text for view that shows many edits were made by bots"), image: UIImage(named: "bot")!, count: botEdits))
            }
            if case let minorEdits?? = editCounts[.minor] {
                counts.append(Count(title: WMFLocalizedString("page-history-minor-edits", value: "minor edits", comment: "Text for view that shows many edits were marked as minor edits"), image: UIImage(named: "reverted")!, count: minorEdits))
            }
            updateLayout(countOfColumns: counts.count)
            delegate?.didDetermineFilterCountsAvailability(!counts.isEmpty, viewController: self)
        }
    }

    private struct Count {
        let title: String
        let image: UIImage
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
        updateLayout()
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
            self.updateLayout()
        })
    }

    private func updateLayout(countOfColumns: Int = 4) {
        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.sectionInset = .zero
        flowLayout.minimumLineSpacing = 0
        let countOfColumns = CGFloat(countOfColumns)
        let availableWidth = collectionView.bounds.width - flowLayout.minimumInteritemSpacing * (countOfColumns - 1) - collectionView.contentInset.left - collectionView.contentInset.right - flowLayout.sectionInset.left - flowLayout.sectionInset.right
        let dimension = floor(availableWidth / countOfColumns)
        flowLayout.estimatedItemSize = CGSize(width: dimension, height: collectionViewHeightConstraint.constant)
    }

    private var flowLayout: UICollectionViewFlowLayout {
        return collectionView.collectionViewLayout as! UICollectionViewFlowLayout
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
        let Count = counts[indexPath.item]
        cell.configure(with: Count.title, image: Count.image, imageText: displayCount(Count.count), isRightSeparatorHidden: indexPath.item == counts.count - 1)
        cell.apply(theme: theme)
        collectionViewHeightConstraint.constant = max(collectionViewHeightConstraint.constant, cell.frame.height)
        return cell
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

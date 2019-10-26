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
            if case let anonEdits?? = editCounts[.anonEdits] {
                counts.append(Count(title: WMFLocalizedString("page-history-ip-edits", value: "IP edits", comment: "Text for view that shows many edits were made by anonymous users - IP refers to the 'IP address'"), image: UIImage(named: "anon")!, count: anonEdits))
            }
            if case let botEdits?? = editCounts[.botEdits] {
                counts.append(Count(title: WMFLocalizedString("page-history-bot-edits", value: "bot edits", comment: "Text for view that shows many edits were made by bots"), image: UIImage(named: "bot")!, count: botEdits))
            }
            if case let revertedEdits?? = editCounts[.revertedEdits] {
                counts.append(Count(title: WMFLocalizedString("page-history-reverted-edits", value: "reverted edits", comment: "Text for view that shows many edits were reverted"), image: UIImage(named: "reverted")!, count: revertedEdits))
            }
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

    override func viewDidLoad() {
        super.viewDidLoad()

        // TODO: Move out into separate types
        collectionView.dataSource = self
        collectionView.register(UINib(nibName: "PageHistoryFilterCountCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: PageHistoryFilterCountCollectionViewCell.identifier)

        // TODO: Adjust height for the highest cell
        let collectionViewHeightConstraint = collectionView.heightAnchor.constraint(equalToConstant: 60)
        collectionViewHeightConstraint.isActive = true
        view.wmf_addSubviewWithConstraintsToEdges(collectionView)
        addActivityIndicator()
        activityIndicator.style = theme.isDark ? .white : .gray
        activityIndicator.startAnimating()

        if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.scrollDirection = .horizontal
            flowLayout.minimumInteritemSpacing = 0
            flowLayout.sectionInset = .zero
            flowLayout.minimumLineSpacing = 0
            let countOfColumns: CGFloat = 4
            let availableWidth = collectionView.bounds.width - flowLayout.minimumInteritemSpacing * (countOfColumns - 1) - collectionView.contentInset.left - collectionView.contentInset.right - flowLayout.sectionInset.left - flowLayout.sectionInset.right
            let dimension = floor(availableWidth / countOfColumns)
            flowLayout.itemSize = CGSize(width: dimension, height: collectionViewHeightConstraint.constant)
        }

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
            if let flowLayout = self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
                let countOfColumns: CGFloat = 4
                let availableWidth = self.collectionView.bounds.width - flowLayout.minimumInteritemSpacing * (countOfColumns - 1) - self.collectionView.contentInset.left - self.collectionView.contentInset.right - flowLayout.sectionInset.left - flowLayout.sectionInset.right
                let dimension = floor(availableWidth / countOfColumns)
                flowLayout.itemSize = CGSize(width: dimension, height: 60)
            }
            self.collectionView.collectionViewLayout.invalidateLayout()
        })
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

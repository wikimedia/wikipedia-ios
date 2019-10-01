import UIKit

class PageHistoryDetailedStatsViewController: UIViewController {
    private let activityIndicator = UIActivityIndicatorView(style: .whiteLarge)
    private let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())

    var theme = Theme.standard

    private var stats: [Stat] = []

    var pageStats: PageStats? {
        didSet {
            guard let minorEdits = pageStats?.minorEdits else {
                stats = []
                return
            }
            stats = [
                Stat(title: "minor edits", image: UIImage(named: "m")!, count: minorEdits),
                Stat(title: "IP edits", image: UIImage(named: "anon")!, count: 5000),
                Stat(title: "bot edits", image: UIImage(named: "bot")!, count: 0),
                Stat(title: "reverted edits", image:UIImage(named: "reverted")!, count: 0)
            ]
            collectionView.reloadData()
            activityIndicator.isHidden = true
        }
    }

    private struct Stat {
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
        collectionView.register(UINib(nibName: "StatCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: StatCollectionViewCell.identifier)

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

extension PageHistoryDetailedStatsViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return stats.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: StatCollectionViewCell.identifier, for: indexPath) as? StatCollectionViewCell else {
            return UICollectionViewCell()
        }
        let stat = stats[indexPath.item]
        cell.configure(with: stat.title, image: stat.image, imageText: displayCount(stat.count), isRightSeparatorHidden: indexPath.item == stats.count - 1)
        cell.apply(theme: theme)
        return cell
    }
}

extension PageHistoryDetailedStatsViewController: Themeable {
    func apply(theme: Theme) {
        guard viewIfLoaded != nil else {
            self.theme = theme
            return
        }
        view.backgroundColor = theme.colors.paperBackground
        collectionView.backgroundColor = view.backgroundColor
        activityIndicator.style = theme.isDark ? .white : .gray
    }
}

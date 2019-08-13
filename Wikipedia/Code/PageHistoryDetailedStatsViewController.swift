import UIKit

class PageHistoryDetailedStatsViewController: UIViewController {
    private let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())

    var theme = Theme.standard

    private struct Stat {
        let title: String
        let image: UIImage
        let count: Int
    }

    private lazy var stats: [Stat] = {
        // TODO: Localize
        let minorEdits = Stat(title: "minor edits", image: #imageLiteral(resourceName: "m"), count: 1)
        let ipEdits = Stat(title: "IP edits", image: #imageLiteral(resourceName: "logged-in"), count: 2)
        let botEdits = Stat(title: "bot edits", image: #imageLiteral(resourceName: "bot"), count: 3)
        let revertedEdits = Stat(title: "reverted edits", image: #imageLiteral(resourceName: "reverted"), count: 4)
        return [minorEdits, ipEdits, botEdits, revertedEdits]
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // TODO: Move out into separate types
        collectionView.dataSource = self
        collectionView.register(UINib(nibName: "StatCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: StatCollectionViewCell.identifier)

        // TODO: Adjust height for the highest cell
        let collectionViewHeightConstraint = collectionView.heightAnchor.constraint(equalToConstant: 60)
        collectionViewHeightConstraint.isActive = true
        view.wmf_addSubviewWithConstraintsToEdges(collectionView)

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
        cell.configure(with: stat.title, image: stat.image, imageText: "\(stat.count)", isRightSeparatorHidden: indexPath.item == stats.count - 1)
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
    }
}

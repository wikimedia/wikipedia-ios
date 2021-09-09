import UIKit

final class NotificationsCenterView: SetupView {

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
		if #available(iOS 13.0, *) {
			let estimatedHeightDimension = NSCollectionLayoutDimension.estimated(130)
			let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),heightDimension: estimatedHeightDimension)
			let item = NSCollectionLayoutItem(layoutSize: itemSize)
			let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),heightDimension: estimatedHeightDimension)
			let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,subitems: [item])
			let section = NSCollectionLayoutSection(group: group)
			let layout = UICollectionViewCompositionalLayout(section: section)
			return layout
		} else {
			fatalError()
		}
	}()

    // MARK: - Setup

    override func setup() {
        backgroundColor = .white
        wmf_addSubviewWithConstraintsToEdges(collectionView)
    }

}

extension NotificationsCenterView: Themeable {

    func apply(theme: Theme) {
        backgroundColor = theme.colors.paperBackground
        collectionView.backgroundColor = theme.colors.paperBackground
    }

}

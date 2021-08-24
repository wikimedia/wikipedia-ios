import UIKit

final class NotificationsCenterView: SetupView {

	// MARK: - Properties

	lazy var collectionView: UICollectionView = {
		return UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
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

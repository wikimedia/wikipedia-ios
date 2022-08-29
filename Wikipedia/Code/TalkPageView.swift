import UIKit

final class TalkPageView: SetupView {

    // MARK: - Private Properties

    private var topicGroupLayout: UICollectionViewLayout {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        return layout
    }

    // MARK: - UI Elements

    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: topicGroupLayout)
        collectionView.register(TalkPageCell.self, forCellWithReuseIdentifier: TalkPageCell.reuseIdentifier)
        collectionView.alwaysBounceVertical = true
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()

    // MARK: - Lifecycle

    override func setup() {
        addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

}

// MARK: - Themeable

extension TalkPageView: Themeable {

    func apply(theme: Theme) {
        collectionView.backgroundColor = theme.colors.baseBackground
    }

}

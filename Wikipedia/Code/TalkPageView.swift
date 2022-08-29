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
    
    private(set) var sizingView: TalkPageCellRootContainerView?

    // MARK: - Lifecycle

    override func setup() {
        addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        
        // Add Sizing View for cell height calculations
        let sizingView = TalkPageCellRootContainerView(frame: .zero)
        sizingView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.insertSubview(sizingView, at: 0)
        let horizontalPadding = TalkPageCell.padding.leading + TalkPageCell.padding.trailing
        NSLayoutConstraint.activate([
            sizingView.topAnchor.constraint(equalTo: collectionView.topAnchor),
            sizingView.leadingAnchor.constraint(equalTo: collectionView.safeAreaLayoutGuide.leadingAnchor),
            sizingView.widthAnchor.constraint(equalTo: safeAreaLayoutGuide.widthAnchor, constant: -horizontalPadding)
        ])
        sizingView.isHidden = true
        self.sizingView = sizingView
    }

}

// MARK: - Themeable

extension TalkPageView: Themeable {

    func apply(theme: Theme) {
        collectionView.backgroundColor = theme.colors.baseBackground
    }

}

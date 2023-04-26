import UIKit

final class TalkPageView: SetupView {

    // MARK: - Private Properties

    private lazy var topicGroupLayout: UICollectionViewLayout = {
        let heightDimension: NSCollectionLayoutDimension = .estimated(225)
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),heightDimension: heightDimension)
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),heightDimension: heightDimension)
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0)
        let layout = UICollectionViewCompositionalLayout(section: section)
        return layout
    }()

    // MARK: - UI Elements

    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: topicGroupLayout)
        collectionView.register(TalkPageCell.self, forCellWithReuseIdentifier: TalkPageCell.reuseIdentifier)
        collectionView.alwaysBounceVertical = true
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()

    lazy var emptyView: TalkPageEmptyView = {
        let view = TalkPageEmptyView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.alpha = 0
        return view
    }()

    lazy var errorView: TalkPageErrorStateView = {
        let view = TalkPageErrorStateView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.alpha = 0
        return view
    }()

    // MARK: - Lifecycle

    override func setup() {
        addSubview(collectionView)
        addSubview(emptyView)
        addSubview(errorView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            emptyView.topAnchor.constraint(equalTo: topAnchor),
            emptyView.bottomAnchor.constraint(equalTo: bottomAnchor),
            emptyView.leadingAnchor.constraint(equalTo: leadingAnchor),
            emptyView.trailingAnchor.constraint(equalTo: trailingAnchor),
            errorView.topAnchor.constraint(equalTo: topAnchor),
            errorView.bottomAnchor.constraint(equalTo: bottomAnchor),
            errorView.leadingAnchor.constraint(equalTo: leadingAnchor),
            errorView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    func updateEmptyView(visible: Bool, animated: Bool = true) {
        UIView.animate(withDuration: animated ? 0.2 : 0, delay: 0, options: .curveEaseInOut, animations: {
            self.emptyView.isUserInteractionEnabled = visible
            self.emptyView.alpha = visible ? 1 : 0
        })
    }

    func updateErrorView(visible: Bool) {
        self.errorView.isUserInteractionEnabled = visible
        self.errorView.alpha = visible ? 1 : 0
    }

    func configure(viewModel: TalkPageViewModel) {
        emptyView.configure(viewModel: viewModel)
    }

}

// MARK: - Themeable

extension TalkPageView: Themeable {

    func apply(theme: Theme) {

        collectionView.backgroundColor = theme.colors.midBackground
        emptyView.apply(theme: theme)
        errorView.apply(theme: theme)
    }

}

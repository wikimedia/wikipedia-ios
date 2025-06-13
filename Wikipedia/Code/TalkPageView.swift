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
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                                  heightDimension: .estimated(225))
        let header = NSCollectionLayoutBoundarySupplementaryItem(
                        layoutSize: headerSize,
                        elementKind: UICollectionView.elementKindSectionHeader,
                        alignment: .top)
        section.boundarySupplementaryItems = [header]
        section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0)
        let layout = UICollectionViewCompositionalLayout(section: section)
        return layout
    }()

    // MARK: - UI Elements

    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: topicGroupLayout)
        collectionView.register(TalkPageCell.self, forCellWithReuseIdentifier: TalkPageCell.reuseIdentifier)
        collectionView.register(TalkPageHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: TalkPageHeaderView.reuseIdentifier)
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
    
    lazy var toolbarContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var toolbar: UIToolbar = {
        let tb = UIToolbar(frame: CGRect(origin: .zero, size: CGSize(width: bounds.width, height: 44)))
        tb.translatesAutoresizingMaskIntoConstraints = false
        return tb
    }()
    
    private var emptyViewTopConstraint: NSLayoutConstraint?
    private var errorViewTopConstraint: NSLayoutConstraint?

    // MARK: - Lifecycle

    override func setup() {
        addSubview(collectionView)
        addSubview(emptyView)
        addSubview(errorView)
        toolbarContainerView.addSubview(toolbar)
        addSubview(toolbarContainerView)
        let emptyViewTopConstraint = emptyView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor)
        let errorViewTopConstraint = errorView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: toolbarContainerView.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            emptyViewTopConstraint,
            emptyView.bottomAnchor.constraint(equalTo: toolbarContainerView.topAnchor),
            emptyView.leadingAnchor.constraint(equalTo: leadingAnchor),
            emptyView.trailingAnchor.constraint(equalTo: trailingAnchor),
            errorViewTopConstraint,
            errorView.bottomAnchor.constraint(equalTo: toolbarContainerView.topAnchor),
            errorView.leadingAnchor.constraint(equalTo: leadingAnchor),
            errorView.trailingAnchor.constraint(equalTo: trailingAnchor),
            toolbarContainerView.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: toolbar.bottomAnchor),
            toolbarContainerView.leadingAnchor.constraint(equalTo: toolbar.leadingAnchor),
            toolbarContainerView.trailingAnchor.constraint(equalTo: toolbar.trailingAnchor),
            toolbarContainerView.topAnchor.constraint(equalTo: toolbar.topAnchor),
            bottomAnchor.constraint(equalTo: toolbarContainerView.bottomAnchor),
            leadingAnchor.constraint(equalTo: toolbarContainerView.leadingAnchor),
            trailingAnchor.constraint(equalTo: toolbarContainerView.trailingAnchor)
        ])
        self.emptyViewTopConstraint = emptyViewTopConstraint
        self.errorViewTopConstraint = errorViewTopConstraint
    }

    func updateEmptyView(visible: Bool, animated: Bool = true) {
        UIView.animate(withDuration: animated ? 0.2 : 0, delay: 0, options: .curveEaseInOut, animations: {
            self.emptyView.isUserInteractionEnabled = visible
            self.emptyView.alpha = visible ? 1 : 0
        })
    }
    
    func updateEmptyErrorViewsTopPadding(padding: CGFloat) {
        emptyViewTopConstraint?.constant = padding
        errorViewTopConstraint?.constant = padding
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
        
        toolbarContainerView.backgroundColor = theme.colors.paperBackground
        toolbar.setBackgroundImage(theme.navigationBarBackgroundImage, forToolbarPosition: .any, barMetrics: .default)
        toolbar.isTranslucent = false
    }

}

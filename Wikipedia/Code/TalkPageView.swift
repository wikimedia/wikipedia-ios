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
    
    lazy var toolbar: UIToolbar = {
        let tb = UIToolbar(frame: .zero)
        tb.translatesAutoresizingMaskIntoConstraints = false
        return tb
    }()

    // MARK: - Lifecycle

    override func setup() {
        addSubview(collectionView)
        addSubview(toolbar)
        addSubview(emptyView)
        addSubview(errorView)
        NSLayoutConstraint.activate([
            toolbar.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            toolbar.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            collectionView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: toolbar.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            emptyView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            emptyView.bottomAnchor.constraint(equalTo: toolbar.topAnchor),
            emptyView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            emptyView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            errorView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            errorView.bottomAnchor.constraint(equalTo: toolbar.topAnchor),
            errorView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            errorView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor)
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
        // TODO: Replace these once new theme colors are added/refreshed in the app
        let baseBackground: UIColor!
        switch theme {
        case .light:
            baseBackground = UIColor.wmf_colorWithHex(0xF8F9FA)
        case .sepia:
            baseBackground = UIColor.wmf_colorWithHex(0xF0E6D6)
        case .dark:
            baseBackground = UIColor.wmf_colorWithHex(0x202122)
        case .black:
            baseBackground = UIColor.wmf_colorWithHex(0x202122)
        default:
            baseBackground = UIColor.wmf_colorWithHex(0xF8F9FA)
        }

        collectionView.backgroundColor = baseBackground
        emptyView.apply(theme: theme)
        errorView.apply(theme: theme)
    }

}

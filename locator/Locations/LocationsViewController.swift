import UIKit
import Combine

/// List of locations to open
class LocationsViewController: UIViewController, StatefulView {
    
    typealias State = LocationsViewState
    
    var onLoad: (() -> Void)?
    var dataSource: UICollectionViewDiffableDataSource<Section, Location>! = nil
    var locationsCollectionView: UICollectionView! = nil
    var bag: Set<AnyCancellable> = []
    private var currentState: State
    
    private let cardsFactory: LocationsViewsFactory
    private let loader = UIActivityIndicatorView.init(style: .large)
    private let presenter: LocationsPresenter
    private let updateHandler: ViewUpdateHandler = .showHideHandler
    
    /// View to show when there is no bookings
    private lazy var noContent: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.text = "No locations found"
        label.textAlignment = .center
        return label
    }()
    
    /// Retry button if loading failed
    private lazy var errorView: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.image = .sfRetry
        configuration.title = "Uh-oh, try again"
        configuration.imagePlacement = .leading
        configuration.imagePadding = .margin2
        let button = UIButton(configuration: configuration, primaryAction: UIAction() { _ in
            self.presenter.retry()
        })
        return button
    }()
    
    init(presenter: LocationsPresenter, cardsFactory: LocationsViewsFactory) {
        self.cardsFactory = cardsFactory
        self.presenter = presenter
        currentState = presenter.state.value
        super.init(nibName: nil, bundle: nil)
        bind(state: presenter.state.eraseToAnyPublisher())
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        onLoad?()
        configureDataSource()
        dataSource.apply(currentState.snapshot, animatingDifferences: false)
    }
    
    func apply(state: State) {
        currentState = state
        updateHandler.handle(
            state.updateState,
            (loader: loader, contentView: locationsCollectionView, error: errorView)
        )

        noContent.isHidden = !state.isEmpty
        dataSource.apply(currentState.snapshot, animatingDifferences: true)
    }
    
    func prepareView() {
        navigationItem.titleView = cardsFactory.makeTitle(currentState.screenTitle)
        configureCollectionView()
        configureViews()
    }
}

extension LocationsViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let section = self.dataSource.sectionIdentifier(for: indexPath.section) else { return }
        if let location = currentState.locationFor(section: section, row: indexPath.row) {
            presenter.select(location: location)
        }
    }
}

private extension LocationsViewController {
    
    func configureViews() {
        view.addSubview(loader)
        view.addSubview(noContent)
        view.addSubview(errorView)
        loader.translatesAutoresizingMaskIntoConstraints = false
        noContent.translatesAutoresizingMaskIntoConstraints = false
        errorView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loader.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loader.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
        NSLayoutConstraint.activate([
            noContent.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            noContent.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
        NSLayoutConstraint.activate([
            errorView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            errorView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }
    
    func configureCollectionView() {
        let collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: .cardsWithSectionTitles)
        view.addSubview(collectionView)
        collectionView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        collectionView.contentInset = .init(top: .margin8, left: .zero, bottom: .zero, right: .zero)
        locationsCollectionView = collectionView
        locationsCollectionView.delegate = self
    }

    func configureDataSource() {
        let inputCell = UICollectionView.CellRegistration<UICollectionViewCell, Location> { cell, indexPath, location in
            cell.contentConfiguration = self.cardsFactory.makeInput(location: location)
        }
        
        let locationCell = UICollectionView.CellRegistration<UICollectionViewCell, Location> { cell, indexPath, location in
            cell.contentConfiguration = self.cardsFactory.makeLocationCard(location, index: indexPath.row)
        }
        
        let locationsHeader = UICollectionView.SupplementaryRegistration<HeaderView>(elementKind: UICollectionView.elementKindSectionHeader) {
            (headerView, _, indexPath) in
            guard let section = self.dataSource.sectionIdentifier(for: indexPath.section) else { return }
            headerView.textLabel.text = self.currentState.titleFor(section: section)
        }
        
        dataSource = UICollectionViewDiffableDataSource<Section, Location>(collectionView: locationsCollectionView) {
            (collectionView: UICollectionView, indexPath: IndexPath, item: Location)
            -> UICollectionViewCell? in
            
            guard let section = self.dataSource.sectionIdentifier(for: indexPath.section) else { return nil }
            switch section {
            case .input:
                return collectionView.dequeueConfiguredReusableCell(using: inputCell, for: indexPath, item: item)
            case .locations:
                return collectionView.dequeueConfiguredReusableCell(using: locationCell, for: indexPath, item: item)
            }
        }
        
        dataSource.supplementaryViewProvider = { (_, _, index) in
            self.locationsCollectionView.dequeueConfiguredReusableSupplementary(using: locationsHeader, for: index)
        }
    }
}

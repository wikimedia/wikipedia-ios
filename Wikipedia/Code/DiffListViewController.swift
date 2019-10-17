
import UIKit

protocol DiffListDelegate: class {
    func diffListScrollViewDidScroll(_ scrollView: UIScrollView)
}

class DiffListViewController: ViewController {
    
    enum ListUpdateType {
        case itemExpandUpdate(indexPath: IndexPath) //tapped context cell to expand
        case layoutUpdate(collectionViewWidth: CGFloat, traitCollection: UITraitCollection) //willTransitionToSize - simple rotation that keeps size class
        case initialLoad(width: CGFloat)
        case theme(theme: Theme)
    }

    lazy private(set) var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.contentInsetAdjustmentBehavior = .never
        scrollView = collectionView
        return collectionView
    }()
    
    private var dataSource: [DiffListGroupViewModel] = []
    private weak var delegate: DiffListDelegate?

    private var updateWidthsOnLayoutSubviews = false
    
    init(theme: Theme, delegate: DiffListDelegate?) {
        super.init(nibName: nil, bundle: nil)
        self.theme = theme
        self.delegate = delegate
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addConstraints([
            view.safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: collectionView.leadingAnchor),
            view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: collectionView.trailingAnchor),
            view.topAnchor.constraint(equalTo: collectionView.topAnchor),
            view.bottomAnchor.constraint(equalTo: collectionView.bottomAnchor)
        ])
        collectionView.register(DiffListChangeCell.wmf_classNib(), forCellWithReuseIdentifier: DiffListChangeCell.reuseIdentifier)
        collectionView.register(DiffListContextCell.wmf_classNib(), forCellWithReuseIdentifier: DiffListContextCell.reuseIdentifier)
        collectionView.register(DiffListUneditedCell.wmf_classNib(), forCellWithReuseIdentifier: DiffListUneditedCell.reuseIdentifier)
    }
    
        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            
            if updateWidthsOnLayoutSubviews {
                let updateType = ListUpdateType.layoutUpdate(collectionViewWidth: collectionView.frame.width, traitCollection: traitCollection)
                backgroundUpdateListViewModels(listViewModel: dataSource, updateType: updateType) {
                    self.applyListViewModelChanges(updateType: updateType)
                }
            }
        }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        updateWidthsOnLayoutSubviews = true
        coordinator.animate(alongsideTransition: { (context) in
        }) { (context) in
            self.updateWidthsOnLayoutSubviews = false
        }
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        
        updateWidthsOnLayoutSubviews = true
        coordinator.animate(alongsideTransition: { (context) in
        }) { (context) in
            self.updateWidthsOnLayoutSubviews = false
        }
        
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)
        delegate?.diffListScrollViewDidScroll(scrollView)
    }
    
    func updateListViewModels(listViewModel: [DiffListGroupViewModel], updateType: DiffListViewController.ListUpdateType) {
        
        switch updateType {
        case .itemExpandUpdate(let indexPath):
            
            if let item = listViewModel[safeIndex: indexPath.item] as? DiffListContextViewModel {
                item.isExpanded.toggle()
            }
            
        case .layoutUpdate(let width, let traitCollection):
            for item in listViewModel {
                if item.width != width || item.traitCollection != traitCollection {
                    item.updateSize(width: width, traitCollection: traitCollection)
                }
            }
        
        case .initialLoad(let width):
            for var item in listViewModel {
                if item.width != width {
                    item.width = width
                }
            }
            self.dataSource = listViewModel
        case .theme(let theme):
            for var item in listViewModel {
                if item.theme != theme {
                    item.theme = theme
                }
            }
        }
    }
    
        func backgroundUpdateListViewModels(listViewModel: [DiffListGroupViewModel], updateType: DiffListViewController.ListUpdateType, completion: @escaping () -> Void) {
    
            let group = DispatchGroup()
            let queue = DispatchQueue(label: "com.wikipedia.diff.heightCalculations", qos: .userInteractive, attributes: .concurrent)
    
            let chunked = listViewModel.chunked(into: 10)
    
            for chunk in chunked {
    
                queue.async(group: group) {
    
                    self.updateListViewModels(listViewModel: chunk, updateType: updateType)
                }
            }
    
            group.notify(queue: DispatchQueue.main) {
                DispatchQueue.main.async {
                    completion()
                }
            }
        }
    
    func applyListViewModelChanges(updateType: DiffListViewController.ListUpdateType) {
        switch updateType {
        case .itemExpandUpdate:
            
            collectionView.setCollectionViewLayout(UICollectionViewFlowLayout(), animated: true)
 
        default:
            collectionView.reloadData()
        }
    }
    
    override func apply(theme: Theme) {
        
        guard isViewLoaded else {
            return
        }
        
        super.apply(theme: theme)
        
        updateListViewModels(listViewModel: dataSource, updateType: .theme(theme: theme))

        collectionView.backgroundColor = theme.colors.paperBackground
    }
}

extension DiffListViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let viewModel = dataSource[safeIndex: indexPath.item] else {
            return UICollectionViewCell()
        }
        
        //tonitodo: clean up
        
        if let viewModel = viewModel as? DiffListChangeViewModel,
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DiffListChangeCell.reuseIdentifier, for: indexPath) as? DiffListChangeCell {
            cell.update(viewModel)
            return cell
        } else if let viewModel = viewModel as? DiffListContextViewModel,
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DiffListContextCell.reuseIdentifier, for: indexPath) as? DiffListContextCell {
            cell.update(viewModel, indexPath: indexPath)
            cell.delegate = self
            return cell
        } else if let viewModel = viewModel as? DiffListUneditedViewModel,
           let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DiffListUneditedCell.reuseIdentifier, for: indexPath) as? DiffListUneditedCell {
           cell.update(viewModel)
           return cell
        }
        
        return UICollectionViewCell()
    }
}

extension DiffListViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        guard let viewModel = dataSource[safeIndex: indexPath.item] else {
            return .zero
        }
        
        if indexPath.item == 0 {
            print("🇲🇩\(collectionView.frame.width)")
            print("😂\(viewModel.width)")
        }
        
        if let contextViewModel = viewModel as? DiffListContextViewModel {
            let height = contextViewModel.isExpanded ? contextViewModel.expandedHeight : contextViewModel.height
            return CGSize(width: min(collectionView.frame.width, contextViewModel.width), height: height)
        }
        
        return CGSize(width: min(collectionView.frame.width, viewModel.width), height: viewModel.height)

    }
}

extension DiffListViewController: DiffListContextCellDelegate {
    func didTapContextExpand(indexPath: IndexPath) {
        
        updateListViewModels(listViewModel: dataSource, updateType: .itemExpandUpdate(indexPath: indexPath))
        applyListViewModelChanges(updateType: .itemExpandUpdate(indexPath: indexPath))
        
        if let contextViewModel = dataSource[safeIndex: indexPath.item] as? DiffListContextViewModel,
        let cell = collectionView.cellForItem(at: indexPath) as? DiffListContextCell {
            cell.update(contextViewModel, indexPath: indexPath)
        }
    }
}

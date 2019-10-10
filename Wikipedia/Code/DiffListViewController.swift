
import UIKit

protocol DiffListDelegate: class {
    func diffListScrollViewDidScroll(_ scrollView: UIScrollView)
    func diffListDidTapIndexPath(_ indexPath: IndexPath)
    func diffListUpdateWidth(newWidth: CGFloat)
}

class DiffListViewController: ViewController {

    lazy private(set) var collectionView: UICollectionView = {
        var layout = UICollectionViewFlowLayout()
        self.layout = layout
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.contentInsetAdjustmentBehavior = .never
        scrollView = collectionView
        return collectionView
    }()
    
    private var layout: UICollectionViewFlowLayout?
    
    //static var counter = 0
    
    private var dataSource: [DiffListGroupViewModel] = []
    private weak var delegate: DiffListDelegate?
    //tonitodo: delete this
    //private var itemSize: CGSize?
    
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
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        delegate?.diffListUpdateWidth(newWidth: collectionView.frame.width)
    }
    
    func update(_ viewModel: [DiffListGroupViewModel]) {
        self.dataSource = viewModel
        //if (DiffListViewController.counter > 1) {
        //    collectionView.setCollectionViewLayout(UICollectionViewFlowLayout(), animated: true)
        //} else {
            collectionView.reloadData()
        //}
        
        //DiffListViewController.counter += 1
    }
    
    override func apply(theme: Theme) {
        guard isViewLoaded else {
            return
        }
        
        super.apply(theme: theme)
        
        collectionView.backgroundColor = theme.colors.paperBackground
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)
        delegate?.diffListScrollViewDidScroll(scrollView)
    }
}

extension DiffListViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard dataSource.count > indexPath.item,
            let viewModel = dataSource[indexPath.item] as? DiffListChangeViewModel else {
                return UICollectionViewCell()
        }
        
        //tonitodo: fix of course
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DiffListChangeCell.reuseIdentifier, for: indexPath) as? DiffListChangeCell {
            cell.update(viewModel)
            return cell
        }
        
        fatalError()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.diffListDidTapIndexPath(indexPath)
    }
}

extension DiffListViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        guard dataSource.count > indexPath.item else {
            return .zero
        }
        
        if let contextViewModel = dataSource[indexPath.item] as? DiffListContextViewModel {
                let height = contextViewModel.isExpanded ? 400 : 200
                return CGSize(width: 250, height: height)
        } else if let changeViewModel = dataSource[indexPath.item] as? DiffListChangeViewModel {
            return CGSize(width: changeViewModel.width, height: changeViewModel.height)
        }
        
        
        return CGSize(width: 250, height: 50)
    }
    
}

//TONITODO: DELETE THIS!!!

extension CGFloat {
    static func random() -> CGFloat {
        return CGFloat(arc4random()) / CGFloat(UInt32.max)
    }
}

extension UIColor {
    static func random() -> UIColor {
        return UIColor(red:   .random(),
                       green: .random(),
                       blue:  .random(),
                       alpha: 1.0)
    }
}

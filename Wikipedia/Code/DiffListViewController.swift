
import UIKit

protocol DiffListDelegate: class {
    func diffListScrollViewDidScroll(_ scrollView: UIScrollView)
    func diffListDidTapIndexPath(_ indexPath: IndexPath)
}

class DiffListViewController: ViewController {

    lazy private(set) var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.contentInsetAdjustmentBehavior = .never
        scrollView = collectionView
        return collectionView
    }()
    
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
        
        view.wmf_addSubviewWithConstraintsToEdges(collectionView)
        collectionView.register(DiffListHighlightCell.wmf_classNib(), forCellWithReuseIdentifier: "testing")
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
        
        //tonitodo: fix of course
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "testing", for: indexPath) as? DiffListHighlightCell {
            cell.backgroundColor = .random()
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
        if dataSource.count > indexPath.item,
            let contextViewModel = dataSource[indexPath.item] as? DiffListContextViewModel {
                let height = contextViewModel.isExpanded ? 400 : 200
                return CGSize(width: 250, height: height)
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

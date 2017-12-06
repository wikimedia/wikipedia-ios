import UIKit

class ReadingListDetailExtendedNavBarView: UIView {
    
}

class ReadingListDetailCollectionViewController: UIViewController {
    
    fileprivate let readingList: ReadingList
    fileprivate let dataStore: MWKDataStore
    
    fileprivate var theme: Theme = Theme.standard
    
    fileprivate var extendedNavBarView: UIView?
    fileprivate var containerView: UIView?

    init(for readingList: ReadingList, dataStore: MWKDataStore) {
        self.readingList = readingList
        self.dataStore = dataStore
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not supported")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        defer {
            apply(theme: theme)
        }
        
        navigationController?.navigationBar.topItem?.title = "Back"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: nil)
        
        extendedNavBarView = ReadingListDetailExtendedNavBarView()
        containerView = UIView()
        guard let extendedNavBarView = extendedNavBarView, let containerView = containerView else {
            return
        }
        
        containerView.addConstraints([containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor), containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor), containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor)])
        view.addSubview(containerView)

        extendedNavBarView.addConstraints([extendedNavBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor), extendedNavBarView.topAnchor.constraint(equalTo: view.topAnchor), extendedNavBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor)])
        view.addSubview(extendedNavBarView)
        
        containerView.addConstraint(containerView.topAnchor.constraint(equalTo: extendedNavBarView.bottomAnchor))
    }

}
extension ReadingListDetailCollectionViewController: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        view.backgroundColor = theme.colors.paperBackground
    }
    
    
}

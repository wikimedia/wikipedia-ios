import UIKit

@objc(WMFSavedViewController)
class SavedViewController: UIViewController, ArticleCollectionViewControllerDelegate {

    public var collectionViewController: SavedCollectionViewController!
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var savedTitleView: UIView!
    
    @objc public var dataStore: MWKDataStore? {
        didSet {
            guard let newValue = dataStore else {
                assertionFailure("cannot set collectionViewController.dataStore to nil")
                return
            }
            collectionViewController.dataStore = newValue
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        let storyBoard = UIStoryboard(name: "Saved", bundle: nil)
        let vc = storyBoard.instantiateViewController(withIdentifier: "SavedCollectionViewController")
        guard let collectionViewController = (vc as? SavedCollectionViewController) else {
            assertionFailure("Could not load SavedCollectionViewController")
            return nil
        }
        self.collectionViewController = collectionViewController
        self.collectionViewController.delegate = self
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        title = WMFLocalizedString("saved-title", value: "Saved", comment: "Title of the saved screen shown on the saved tab\n{{Identical|Saved}}")
        wmf_updateNavigationBar(removeUnderline: true)
        self.addChildViewController(collectionViewController)
        self.collectionViewController.view.frame = self.containerView.bounds
        self.collectionViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.containerView.addSubview(collectionViewController.view)
        self.collectionViewController.didMove(toParentViewController: self)
        
        let searchBarHeight: CGFloat = 32
        let searchBarLeadingPadding: CGFloat = 7.5
        let searchBarTrailingPadding: CGFloat = 2.5
        
        //        searchBar = titleViewSearchBar
        
        savedTitleView.frame = CGRect(x: searchBarLeadingPadding, y: 0, width: view.bounds.size.width - searchBarLeadingPadding - searchBarTrailingPadding, height: searchBarHeight)
        
        let titleView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.size.width, height: searchBarHeight))
        titleView.addSubview(savedTitleView)
        titleView.wmf_addConstraintsToEdgesOfView(savedTitleView, withInsets: UIEdgeInsets(top: 0, left: searchBarLeadingPadding, bottom: 0, right: searchBarTrailingPadding), priority: .defaultHigh)
        navigationItem.titleView = titleView
    }
}

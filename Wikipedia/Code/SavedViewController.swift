import UIKit

@objc(WMFSavedViewController)
class SavedViewController: UIViewController, ArticleCollectionViewControllerDelegate {

    public var collectionViewController: SavedCollectionViewController!
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var savedTitleView: UIView!
    @IBOutlet weak var editButton: UIButton!
    
    @IBOutlet weak var extendedNavBarView: UIView!
    @IBOutlet weak var searchBar: UISearchBar!
//    @IBOutlet weak var sortButton: UIButton!
    
    @IBOutlet fileprivate var savedArticlesButton: UIButton?
    @IBOutlet fileprivate var readingListsButton: UIButton?
    
    fileprivate var theme: Theme = Theme.standard
    
    @objc public var dataStore: MWKDataStore? {
        didSet {
            guard let newValue = dataStore else {
                assertionFailure("cannot set collectionViewController.dataStore to nil")
                return
            }
            title = WMFLocalizedString("saved-title", value: "Saved", comment: "Title of the saved screen shown on the saved tab\n{{Identical|Saved}}") // change
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
        
        apply(theme: self.theme)
        
        searchBar.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        searchBar.returnKeyType = .search
        searchBar.searchBarStyle = .minimal
        searchBar.placeholder = WMFLocalizedString("saved-search-default-text", value:"Search ", comment:"tbd")
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        wmf_updateNavigationBar(removeUnderline: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        wmf_updateNavigationBar(removeUnderline: false)
    }
}

extension SavedViewController: UISearchBarDelegate {
    
}

extension SavedViewController: Themeable {
    
    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        view.backgroundColor = theme.colors.paperBackground
        editButton.tintColor = theme.colors.link
        
        savedArticlesButton?.setTitleColor(theme.colors.secondaryText, for: .normal)
        savedArticlesButton?.tintColor = theme.colors.link
        
        readingListsButton?.setTitleColor(theme.colors.secondaryText, for: .normal)
        readingListsButton?.tintColor = theme.colors.link
        
        extendedNavBarView.backgroundColor = theme.colors.chromeBackground
        searchBar.setSearchFieldBackgroundImage(theme.searchBarBackgroundImage, for: .normal)
        searchBar.wmf_enumerateSubviewTextFields{ (textField) in
            textField.textColor = theme.colors.primaryText
            textField.keyboardAppearance = theme.keyboardAppearance
            textField.font = UIFont.systemFont(ofSize: 14)
        }
        searchBar.searchTextPositionAdjustment = UIOffset(horizontal: 7, vertical: 0)
    }
}

import UIKit

@objc(WMFSavedViewController)
class SavedViewController: UIViewController, ArticleCollectionViewControllerDelegate {

    fileprivate var savedArticlesCollectionViewController: SavedCollectionViewController!
    
    fileprivate lazy var readingListsCollectionViewController: ReadingListsCollectionViewController? = {
        guard let dataStore = dataStore else {
            return nil
        }
        return ReadingListsCollectionViewController(with: dataStore)
    }()

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var savedTitleView: UIView!
    @IBOutlet weak var savedTitleLabel: UILabel!
    
    @IBOutlet weak var extendedNavBarView: UIView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    @IBOutlet weak var savedArticlesButton: UIButton!
    @IBOutlet weak var readingListsButton: UIButton!
    
    fileprivate var currentView: View = .savedArticles {
        didSet {
            
            guard oldValue != currentView else {
                return
            }
            
            switch currentView {
            case .savedArticles:
                removeChild(readingListsCollectionViewController)
                addChild(savedArticlesCollectionViewController)
            case .readingLists :
                removeChild(savedArticlesCollectionViewController)
                addChild(readingListsCollectionViewController)
            }
        }
    }
    
    fileprivate var theme: Theme = Theme.standard
    
    @objc public var dataStore: MWKDataStore? {
        didSet {
            guard let newValue = dataStore else {
                assertionFailure("cannot set dataStore to nil")
                return
            }
            title = WMFLocalizedString("saved-title", value: "Saved", comment: "Title of the saved screen shown on the saved tab\n{{Identical|Saved}}") // change
            savedArticlesCollectionViewController.dataStore = newValue
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        savedArticlesCollectionViewController = SavedCollectionViewController()
        savedArticlesCollectionViewController.delegate = self
        
    }
    
    fileprivate enum View {
        case savedArticles, readingLists
    }
    
    fileprivate func addChild(_ vc: UICollectionViewController?) {
        guard let vc = vc else {
            return
        }
        addChildViewController(vc)
        vc.view.frame = containerView.bounds
        vc.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        containerView.addSubview(vc.view)
        vc.didMove(toParentViewController: self)
    }
    
    fileprivate func removeChild(_ vc: UICollectionViewController?) {
        guard let vc = vc else {
            return
        }
        vc.view.removeFromSuperview()
        vc.willMove(toParentViewController: nil)
        vc.removeFromParentViewController()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addChild(savedArticlesCollectionViewController)

        let searchBarHeight: CGFloat = 32
        let searchBarLeadingPadding: CGFloat = 7.5
        let searchBarTrailingPadding: CGFloat = 2.5
        
        savedTitleView.frame = CGRect(x: searchBarLeadingPadding, y: 0, width: view.bounds.size.width - searchBarLeadingPadding - searchBarTrailingPadding, height: searchBarHeight)
        
        let titleView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.size.width, height: searchBarHeight))
        titleView.addSubview(savedTitleView)
        titleView.wmf_addConstraintsToEdgesOfView(savedTitleView, withInsets: UIEdgeInsets(top: 0, left: searchBarLeadingPadding, bottom: 0, right: searchBarTrailingPadding), priority: .defaultHigh)
        navigationItem.titleView = titleView
        
        searchBar.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        searchBar.returnKeyType = .search
        searchBar.searchBarStyle = .minimal
        searchBar.placeholder = WMFLocalizedString("saved-search-default-text", value:"Search ", comment:"tbd")
        
        addHairlines(to: [savedArticlesButton, readingListsButton])
        
        apply(theme: self.theme)
    }
    
    fileprivate func addHairlines(to buttons: [UIButton]) {

        for button in buttons {
            let hairline = UIView()
            let hairlineHeight: CGFloat = 0.5
            hairline.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
            hairline.frame = CGRect(x: 0, y: button.bounds.height - (hairlineHeight * 2), width: button.bounds.width, height: hairlineHeight)
            hairline.backgroundColor = button.titleColor(for: .normal)
            button.addSubview(hairline)
            buttonHairlines.append(hairline)
        }

    }
    
    fileprivate var buttonHairlines: [UIView] = []
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        wmf_updateNavigationBar(removeUnderline: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        wmf_updateNavigationBar(removeUnderline: false)
    }
    
    @IBAction func readingListsButtonPressed(_ sender: UIButton) {
        savedArticlesButton.isSelected = false
        readingListsButton.isSelected = true
        currentView = .readingLists
    }
    
    @IBAction func savedArticlesButtonPressed(_ sender: UIButton) {
        readingListsButton.isSelected = false
        savedArticlesButton.isSelected = true
        currentView = .savedArticles
    }
    
}

extension SavedViewController: Themeable {
    
    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        view.backgroundColor = theme.colors.paperBackground
        
        savedArticlesCollectionViewController.apply(theme: theme)
        
        savedArticlesButton?.setTitleColor(theme.colors.secondaryText, for: .normal)
        savedArticlesButton?.tintColor = theme.colors.link
        
        readingListsButton?.setTitleColor(theme.colors.secondaryText, for: .normal)
        readingListsButton?.tintColor = theme.colors.link
        
        for hairline in buttonHairlines {
            hairline.backgroundColor = theme.colors.border
        }
        
        extendedNavBarView.backgroundColor = theme.colors.chromeBackground
        searchBar.setSearchFieldBackgroundImage(theme.searchBarBackgroundImage, for: .normal)
        searchBar.wmf_enumerateSubviewTextFields{ (textField) in
            textField.textColor = theme.colors.primaryText
            textField.keyboardAppearance = theme.keyboardAppearance
            textField.font = UIFont.systemFont(ofSize: 14)
        }
        searchBar.searchTextPositionAdjustment = UIOffset(horizontal: 7, vertical: 0)
        
        savedTitleLabel.textColor = theme.colors.primaryText
    }
}

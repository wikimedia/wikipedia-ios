import UIKit

@objc(WMFSavedViewController)
class SavedViewController: UIViewController {

    fileprivate var savedArticlesCollectionViewController: SavedArticlesCollectionViewController!
    
    fileprivate lazy var readingListsCollectionViewController: ReadingListsCollectionViewController? = {
        guard let dataStore = dataStore else {
            assertionFailure("dataStore is nil")
            return nil
        }
        return ReadingListsCollectionViewController(with: dataStore)
    }()
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var savedTitleView: UIView!
    @IBOutlet weak var savedTitleLabel: UILabel!
    
    @IBOutlet weak var extendedNavBarView: UIView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    @IBOutlet var toggleButtons: [UIButton]!
    
    fileprivate var activeChildViewController: UICollectionViewController?
    
    fileprivate var currentView: View = .savedArticles {
        didSet {
            switch currentView {
            case .savedArticles:
                removeChild(readingListsCollectionViewController)
                activeChildViewController = savedArticlesCollectionViewController
                
                navigationItem.leftBarButtonItem = nil
                
                addChild(activeChildViewController)
                
            case .readingLists :
                removeChild(savedArticlesCollectionViewController)
                activeChildViewController = readingListsCollectionViewController
                
                navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: readingListsCollectionViewController.self, action: #selector(readingListsCollectionViewController?.presentCreateReadingListViewController))
                
                addChild(activeChildViewController)
                
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
        savedArticlesCollectionViewController = SavedArticlesCollectionViewController()
    }
    
    fileprivate enum View: Int {
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
        
        currentView = .savedArticles
        
        savedArticlesCollectionViewController.delegate = readingListsCollectionViewController
        
        collectionViewBatchEditController.delegate = self
        
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
        
        addHairlines(to: toggleButtons)
        
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
    
    @IBAction func toggleButtonPressed(_ sender: UIButton) {
        toggleButtons.first { $0.tag != sender.tag }?.isSelected = false
        sender.isSelected = true
        currentView = View(rawValue: sender.tag) ?? .savedArticles
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
        readingListsCollectionViewController?.apply(theme: theme)
        
        for button in toggleButtons {
            button.setTitleColor(theme.colors.secondaryText, for: .normal)
            button.tintColor = theme.colors.link
        }

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

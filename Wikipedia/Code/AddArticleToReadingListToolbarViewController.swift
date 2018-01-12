import UIKit

@objc public protocol ReadingListHintProvider: NSObjectProtocol {
    var addArticleToReadingListToolbarController: AddArticleToReadingListToolbarController? { get set }
}

protocol AddArticleToReadingListToolbarViewControllerDelegate: NSObjectProtocol {
    func viewControllerWillBeDismissed()
    func addedArticleToReadingList()
}

@objc(WMFAddArticleToReadingListToolbarController)
public class AddArticleToReadingListToolbarController: NSObject, AddArticleToReadingListToolbarViewControllerDelegate {

    fileprivate let dataStore: MWKDataStore
    fileprivate let owner: UIViewController
    fileprivate let toolbar: AddArticleToReadingListToolbarViewController
    fileprivate let toolbarHeight: CGFloat = 50
    fileprivate var theme: Theme = Theme.standard
    
    fileprivate var isToolbarVisible = false {
        didSet {
            guard isToolbarVisible != oldValue else {
                return
            }
            if isToolbarVisible {
                addToolbar()
                dismissToolbar()
            } else {
                removeToolbar()
            }
        }
    }
    
    @objc init(dataStore: MWKDataStore, owner: UIViewController) {
        self.dataStore = dataStore
        self.owner = owner
        self.toolbar = AddArticleToReadingListToolbarViewController(dataStore: dataStore)
        super.init()
        self.toolbar.delegate = self
    }
    
    func removeToolbar() {
        toolbar.willMove(toParentViewController: nil)
        toolbar.view.removeFromSuperview()
        toolbar.removeFromParentViewController()
        toolbar.reset()
    }
    
    func addToolbar() {
        toolbar.apply(theme: theme)
        owner.addChildViewController(toolbar)
        toolbar.view.autoresizingMask = [.flexibleTopMargin, .flexibleWidth]
        owner.view.addSubview(toolbar.view)
        toolbar.didMove(toParentViewController: owner)
    }
    
    func dismissToolbar() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(setToolbar(visible:)), object: false)
        perform(#selector(setToolbar(visible:)), with: false, afterDelay: 8)
    }
    
    @objc func setToolbar(visible: Bool) {
        let frame = visible ? toolbarFrame.visible : toolbarFrame.hidden
            if visible {
                // add toolbar before animation starts
                isToolbarVisible = visible
                // set initial frame
                if toolbar.view.frame.origin.y == 0 {
                    toolbar.view.frame = toolbarFrame.hidden
                }
            }
            if let articleNavigationController = owner.navigationController as? WMFArticleNavigationController {
                articleNavigationController.setSecondToolbarHidden(visible, animated: true)
            }
            UIView.animate(withDuration: 0.4, delay: 0, options: [.curveEaseInOut, .beginFromCurrentState], animations: {
                self.toolbar.view.frame = frame
                self.owner.view.setNeedsLayout()
            }, completion: { (_) in
                if !visible {
                    // remove toolbar after animation is completed
                    self.isToolbarVisible = visible
                }
            })
    }
    
    fileprivate lazy var toolbarFrame: (visible: CGRect, hidden: CGRect) = {
        let visible = CGRect(x: 0, y: owner.view.bounds.height - toolbarHeight - owner.bottomLayoutGuide.length, width: owner.view.bounds.size.width, height: toolbarHeight)
        let hidden = CGRect(x: 0, y: owner.view.bounds.height + toolbarHeight - owner.bottomLayoutGuide.length, width: owner.view.bounds.size.width, height: toolbarHeight)
        return (visible: visible, hidden: hidden)
    }()
    
    @objc func didSave(_ didSave: Bool, article: WMFArticle, theme: Theme) {
        
        self.theme = theme
        
        let didSaveOtherArticle = didSave && isToolbarVisible && article != toolbar.article
        let didUnsaveOtherArticle = !didSave && isToolbarVisible && article != toolbar.article
        
        guard !didUnsaveOtherArticle else {
            return
        }
        
        guard !didSaveOtherArticle else {
            toolbar.reset()
            dismissToolbar()
            toolbar.article = article
            return
        }
        
        toolbar.article = article
        setToolbar(visible: didSave)
    }
    
    @objc func didSave(_ saved: Bool, articleURL: URL, theme: Theme) {
        guard let article = dataStore.fetchArticle(with: articleURL) else {
            return
        }
        didSave(saved, article: article, theme: theme)
    }
    
    // MARK: - AddArticleToReadingListToolbarViewControllerDelegate
    
    func viewControllerWillBeDismissed() {
        self.setToolbar(visible: false)
    }
    
    func addedArticleToReadingList() {
        self.setToolbar(visible: true)
    }
}

@objc(WMFAddArticleToReadingListToolbarViewController)
class AddArticleToReadingListToolbarViewController: UIViewController {
    
    fileprivate let dataStore: MWKDataStore
    fileprivate var theme: Theme = Theme.standard
    
    var article: WMFArticle? {
        didSet {
            let articleTitle = article?.displayTitle ?? "article"
            button.setTitle("Add \(articleTitle) to reading list", for: .normal)
        }
    }
    
    public init(dataStore: MWKDataStore) {
        self.dataStore = dataStore
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate var button: AlignedImageButton = AlignedImageButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(button)
        button.titleLabel?.lineBreakMode = .byTruncatingTail
        button.verticalPadding = 5
        button.setImage(UIImage(named: "add-to-list"), for: .normal)
        button.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        button.sizeToFit()
        button.translatesAutoresizingMaskIntoConstraints = false
        let centerConstraint = button.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        let leadingConstraint = button.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12)
        let trailingConstraint = view.trailingAnchor.constraint(greaterThanOrEqualTo: button.trailingAnchor, constant: 12)
        centerConstraint.isActive = true
        leadingConstraint.isActive = true
        trailingConstraint.isActive = true
        apply(theme: theme)
    }
    
    func reset() {
        let articleTitle = article?.displayTitle ?? "article"
        button.setTitle("Add \(articleTitle) to reading list", for: .normal)
        button.setImage(UIImage(named: "add-to-list"), for: .normal)
        button.removeTarget(self, action: #selector(openReadingList), for: .touchUpInside)
        button.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        button.titleLabel?.setFont(with: .systemMedium, style: .subheadline, traitCollection: traitCollection)
    }
    
    public weak var delegate: AddArticleToReadingListToolbarViewControllerDelegate?
    
    @objc fileprivate func buttonPressed() {
        guard let article = article else {
            return
        }
        let addArticlesToReadingListViewController = AddArticlesToReadingListViewController(with: dataStore, articles: [article], theme: theme)
        addArticlesToReadingListViewController.delegate = self
        present(addArticlesToReadingListViewController, animated: true, completion: nil)
    }
    
    fileprivate var readingList: ReadingList?
    
    @objc fileprivate func openReadingList() {
        guard let readingList = readingList else {
            return
        }
        
        if readingList.isDefaultList {
           let viewController = SavedArticlesViewController()
            viewController.dataStore = dataStore
            viewController.apply(theme: theme)
            wmf_push(viewController, animated: true)
        } else {
            let viewController = ReadingListDetailViewController(for: readingList, with: dataStore)
            viewController.apply(theme: theme)
            wmf_push(viewController, animated: true)
        }
        delegate?.viewControllerWillBeDismissed()
    }

}

extension AddArticleToReadingListToolbarViewController: AddArticlesToReadingListDelegate {
    func viewControllerWillBeDismissed() {
        delegate?.viewControllerWillBeDismissed()
    }
    
    func addedArticle(to readingList: ReadingList) {
        guard let name = readingList.isDefaultList ? CommonStrings.shortSavedTitle : readingList.name else {
            return
        }
        self.readingList = readingList
        button.setTitle("Article added to \(name)", for: .normal)
        button.setImage(nil, for: .normal)
        button.removeTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        button.addTarget(self, action: #selector(openReadingList), for: .touchUpInside)
        delegate?.addedArticleToReadingList()
    }
}

extension AddArticleToReadingListToolbarViewController: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        view.backgroundColor = theme.colors.disabledLink
        button.setTitleColor(theme.colors.link, for: .normal)
    }
}

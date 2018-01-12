import UIKit

@objc public protocol ReadingListHintPresenter: NSObjectProtocol {
    var readingListHintController: ReadingListHintController? { get set }
}

protocol ReadingListHintViewControllerDelegate: NSObjectProtocol {
    func viewControllerWillBeDismissed()
    func addedArticleToReadingList()
}

@objc(WMFReadingListHintController)
public class ReadingListHintController: NSObject, ReadingListHintViewControllerDelegate {

    fileprivate let dataStore: MWKDataStore
    fileprivate let presenter: UIViewController
    fileprivate let hint: ReadingListHintViewController
    fileprivate let hintHeight: CGFloat = 50
    fileprivate var theme: Theme = Theme.standard
    
    fileprivate var isHintVisible = false {
        didSet {
            guard isHintVisible != oldValue else {
                return
            }
            if isHintVisible {
                addHint()
                dismissHint()
            } else {
                removeHint()
            }
        }
    }
    
    @objc init(dataStore: MWKDataStore, presenter: UIViewController) {
        self.dataStore = dataStore
        self.presenter = presenter
        self.hint = ReadingListHintViewController(dataStore: dataStore)
        super.init()
        self.hint.delegate = self
    }
    
    func removeHint() {
        hint.willMove(toParentViewController: nil)
        hint.view.removeFromSuperview()
        hint.removeFromParentViewController()
        hint.reset()
    }
    
    func addHint() {
        hint.apply(theme: theme)
        presenter.addChildViewController(hint)
        hint.view.autoresizingMask = [.flexibleTopMargin, .flexibleWidth]
        presenter.view.addSubview(hint.view)
        hint.didMove(toParentViewController: presenter)
    }
    
    func dismissHint() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(setHint(visible:)), object: false)
        perform(#selector(setHint(visible:)), with: false, afterDelay: 8)
    }
    
    @objc func setHint(visible: Bool) {
        let frame = visible ? hintFrame.visible : hintFrame.hidden
            if visible {
                // add toolbar before animation starts
                isHintVisible = visible
                // set initial frame
                if hint.view.frame.origin.y == 0 {
                    hint.view.frame = hintFrame.hidden
                }
            }

            UIView.animate(withDuration: 0.4, delay: 0, options: [.curveEaseInOut, .beginFromCurrentState], animations: {
                self.hint.view.frame = frame
                self.hint.view.setNeedsLayout()
            }, completion: { (_) in
                if !visible {
                    // remove toolbar after animation is completed
                    self.isHintVisible = visible
                }
            })
    }
    
    fileprivate lazy var hintFrame: (visible: CGRect, hidden: CGRect) = {
        let visible = CGRect(x: 0, y: presenter.view.bounds.height - hintHeight - presenter.bottomLayoutGuide.length, width: presenter.view.bounds.size.width, height: hintHeight)
        let hidden = CGRect(x: 0, y: presenter.view.bounds.height + hintHeight - presenter.bottomLayoutGuide.length, width: presenter.view.bounds.size.width, height: hintHeight)
        return (visible: visible, hidden: hidden)
    }()
    
    @objc func didSave(_ didSave: Bool, article: WMFArticle, theme: Theme) {
        
        self.theme = theme
        
        let didSaveOtherArticle = didSave && isHintVisible && article != hint.article
        let didUnsaveOtherArticle = !didSave && isHintVisible && article != hint.article
        
        guard !didUnsaveOtherArticle else {
            return
        }
        
        guard !didSaveOtherArticle else {
            hint.reset()
            dismissHint()
            hint.article = article
            return
        }
        
        hint.article = article
        setHint(visible: didSave)
    }
    
    @objc func didSave(_ saved: Bool, articleURL: URL, theme: Theme) {
        guard let article = dataStore.fetchArticle(with: articleURL) else {
            return
        }
        didSave(saved, article: article, theme: theme)
    }
    
    // MARK: - AddArticleToReadingListToolbarViewControllerDelegate
    
    func viewControllerWillBeDismissed() {
        setHint(visible: false)
    }
    
    func addedArticleToReadingList() {
        setHint(visible: true)
    }
}

class ReadingListHintViewController: UIViewController {
    
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
    
    public weak var delegate: ReadingListHintViewControllerDelegate?
    
    @objc fileprivate func buttonPressed() {
        guard let article = article else {
            return
        }
        let addArticlesToReadingListViewController = AddArticlesToReadingListViewController(with: dataStore, articles: [article], theme: theme)
        addArticlesToReadingListViewController.delegate = self
        present(addArticlesToReadingListViewController, animated: true, completion: nil)
    }
    
    fileprivate var readingList: ReadingList?
    fileprivate var themeableNavigationController: WMFThemeableNavigationController?
    
    @objc fileprivate func openReadingList() {
        guard let readingList = readingList else {
            return
        }
        
        let viewController = readingList.isDefaultList ? SavedArticlesViewController() : ReadingListDetailViewController(for: readingList, with: dataStore)
        (viewController as? SavedArticlesViewController)?.dataStore = dataStore
        viewController.navigationItem.leftBarButtonItem = UIBarButtonItem.wmf_buttonType(WMFButtonType.X, target: self, action: #selector(dismissReadingListDetailViewController))
        viewController.apply(theme: theme)
        let navigationController = WMFThemeableNavigationController(rootViewController: viewController, theme: theme)
        themeableNavigationController = navigationController
        present(navigationController, animated: true) {
            self.delegate?.viewControllerWillBeDismissed()
        }
    }
    
    @objc private func dismissReadingListDetailViewController() {
        themeableNavigationController?.dismiss(animated: true, completion: nil)
    }

}

extension ReadingListHintViewController: AddArticlesToReadingListDelegate {
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

extension ReadingListHintViewController: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        view.backgroundColor = theme.colors.disabledLink
        button.setTitleColor(theme.colors.link, for: .normal)
    }
}

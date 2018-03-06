import UIKit

@objc public protocol ReadingListHintPresenter: class {
    var readingListHintController: ReadingListHintController? { get set }
}

protocol ReadingListHintViewControllerDelegate: class {
    func readingListHint(_ readingListHint: ReadingListHintViewController, shouldBeHidden: Bool)
}

@objc(WMFReadingListHintController)
public class ReadingListHintController: NSObject, ReadingListHintViewControllerDelegate {

    private let dataStore: MWKDataStore
    private weak var presenter: UIViewController?
    private let hint: ReadingListHintViewController
    private let hintHeight: CGFloat = 50
    private var theme: Theme = Theme.standard
    private var didSaveArticle: Bool = false
    private var isPresentingPanel: Bool = false
    
    private var isHintHidden = true {
        didSet {
            guard isHintHidden != oldValue else {
                return
            }
            if isHintHidden {
                removeHint()
            } else {
                addHint()
                dismissHint()
            }
        }
    }
        
    @objc init(dataStore: MWKDataStore, presenter: UIViewController) {
        self.dataStore = dataStore
        self.presenter = presenter
        self.hint = ReadingListHintViewController()
        self.hint.dataStore = dataStore
        super.init()
        self.hint.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(entriesLimitReached(notification:)), name: ReadingList.entriesLimitReachedNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: ReadingList.entriesLimitReachedNotification, object: nil)
    }
    
    @objc private func entriesLimitReached(notification: Notification) {
        guard let userInfo = notification.userInfo, let readingList = userInfo[ReadingList.entriesLimitReachedReadingListKey] as? ReadingList, let entriesLimitReached = userInfo[ReadingList.entriesLimitReachedKey] as? Bool else {
            return
        }
        guard readingList.isDefault && entriesLimitReached else {
            return
        }
        guard dataStore.readingListsController.isSyncEnabled else {
            return
        }
        // !UserDefaults.wmf_userDefaults().wmf_didShowLimitHitForUnsortedArticlesPanel()
        if true {
            isPresentingPanel = true
            let primaryButtonHandler: ScrollableEducationPanelButtonTapHandler = { _ in
                self.presenter?.presentedViewController?.dismiss(animated: true)
                let readingListDetailViewController = ReadingListDetailViewController(for: readingList, with: self.dataStore, displayType: .modal)
                readingListDetailViewController.apply(theme: self.theme)
                let navigationController = WMFThemeableNavigationController(rootViewController: readingListDetailViewController, theme: self.theme)
                self.presenter?.present(navigationController, animated: true)
            }
            presenter?.wmf_showLimitHitForUnsortedArticlesPanelViewController(theme: theme, primaryButtonTapHandler: primaryButtonHandler) {
                self.isPresentingPanel = false
                UserDefaults.wmf_userDefaults().wmf_setDidShowLimitHitForUnsortedArticlesPanel(true)
            }
        }
    }
    
    func removeHint() {
        task?.cancel()
        hint.willMove(toParentViewController: nil)
        hint.view.removeFromSuperview()
        hint.removeFromParentViewController()
        resetHint()
    }
    
    func addHint() {
        hint.apply(theme: theme)
        presenter?.addChildViewController(hint)
        hint.view.autoresizingMask = [.flexibleTopMargin, .flexibleWidth]
        presenter?.view.addSubview(hint.view)
        hint.didMove(toParentViewController: presenter)
    }
    
    var hintVisibilityTime: TimeInterval = 13 {
        didSet {
            guard hintVisibilityTime != oldValue else {
                return
            }
            dismissHint()
        }
    }
    
    private var task: DispatchWorkItem?
    
    func updateRandom(_ hintHidden: Bool) {
        if let navigationController = (presenter as? WMFRandomArticleViewController)?.navigationController as? WMFArticleNavigationController {
            navigationController.readingListHintHeight = hintHeight
            navigationController.readingListHintHidden = hintHidden
        }
    }
    
    func dismissHint() {
        self.task?.cancel()
        let task = DispatchWorkItem { self.setHintHidden(true) }
        DispatchQueue.main.asyncAfter(deadline: .now() + hintVisibilityTime , execute: task)
        self.task = task
    }
    
    @objc func setHintHidden(_ hintHidden: Bool) {
        let frame = hintHidden ? hintFrame.hidden : hintFrame.visible
        if !hintHidden {
            // add hint before animation starts
            addHint()
            // set initial frame
            if hint.view.frame.origin.y == 0 {
                hint.view.frame = hintFrame.hidden
            }
        }
        
        updateRandom(hintHidden)
        
        UIView.animate(withDuration: 0.4, delay: 0, options: [.curveEaseInOut, .beginFromCurrentState], animations: {
            self.hint.view.frame = frame
            self.hint.view.setNeedsLayout()
        }, completion: { (_) in
            // remove hint after animation is completed
            self.isHintHidden = hintHidden
            if hintHidden {
                self.updateRandom(hintHidden)
            }
        })
    }
    
    private lazy var hintFrame: (visible: CGRect, hidden: CGRect) = {
        guard let presenter = presenter else {
            return (.zero, .zero)
        }
        let visible = CGRect(x: 0, y: presenter.view.bounds.height - hintHeight - presenter.bottomLayoutGuide.length, width: presenter.view.bounds.size.width, height: hintHeight)
        let hidden = CGRect(x: 0, y: presenter.view.bounds.height + hintHeight - presenter.bottomLayoutGuide.length, width: presenter.view.bounds.size.width, height: hintHeight)
        return (visible: visible, hidden: hidden)
    }()
    
    @objc func didSave(_ didSave: Bool, article: WMFArticle, theme: Theme) {
        guard !isPresentingPanel else {
            return
        }
        
        didSaveArticle = didSave
        self.theme = theme
        
        let didSaveOtherArticle = didSave && !isHintHidden && article != hint.article
        let didUnsaveOtherArticle = !didSave && !isHintHidden && article != hint.article
        
        guard !didUnsaveOtherArticle else {
            return
        }
        
        guard !didSaveOtherArticle else {
            resetHint()
            dismissHint()
            hint.article = article
            return
        }
        
        hint.article = article
        setHintHidden(!didSave)
    }
    
    private func resetHint() {
        didSaveArticle = false
        hintVisibilityTime = 13
        hint.reset()
    }
    
    @objc func didSave(_ saved: Bool, articleURL: URL, theme: Theme) {
        guard let article = dataStore.fetchArticle(with: articleURL) else {
            return
        }
        didSave(saved, article: article, theme: theme)
    }
    
    @objc func scrollViewWillBeginDragging() {
        guard !isHintHidden else {
            return
        }
        hintVisibilityTime = 0
    }
    
    // MARK: - ReadingListHintViewControllerDelegate
    
    func readingListHint(_ readingListHint: ReadingListHintViewController, shouldBeHidden: Bool) {
        setHintHidden(shouldBeHidden)
    }
}

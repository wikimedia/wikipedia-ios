import UIKit

@objc public protocol ReadingListHintPresenter: NSObjectProtocol {
    var readingListHintController: ReadingListHintController? { get set }
}

protocol ReadingListHintViewControllerDelegate: NSObjectProtocol {
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
    }
    
    func removeHint() {
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
    
    func dismissHint() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(setHintHidden), object: 1)
        perform(#selector(setHintHidden), with: 1, afterDelay: hintVisibilityTime)
    }
    
    @objc func setHintHidden(_ hintHidden: Bool) {
        let frame = hintHidden ? hintFrame.hidden : hintFrame.visible
        if !hintHidden {
            // add hint before animation starts
            isHintHidden = hintHidden
            // set initial frame
            if hint.view.frame.origin.y == 0 {
                hint.view.frame = hintFrame.hidden
            }
        }
        
        if let randomArticleViewController = presenter as? WMFRandomArticleViewController {
            randomArticleViewController.isReadingListHintHidden = hintHidden
        }

        UIView.animate(withDuration: 0.4, delay: 0, options: [.curveEaseInOut, .beginFromCurrentState], animations: {
            self.hint.view.frame = frame
            self.hint.view.setNeedsLayout()
        }, completion: { (_) in
            // remove hint after animation is completed
            self.isHintHidden = hintHidden
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
        didSaveArticle = true
        
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
    
    @objc func hideHintImmediately() {
        isHintHidden = true
    }
    
    @objc func didSave(_ saved: Bool, articleURL: URL, theme: Theme) {
        guard let article = dataStore.fetchArticle(with: articleURL) else {
            return
        }
        didSave(saved, article: article, theme: theme)
    }
    
    @objc func scrollViewWillBeginDragging() {
        guard didSaveArticle else {
            return
        }
        hintVisibilityTime = 8
    }
    
    // MARK: - ReadingListHintViewControllerDelegate
    
    func readingListHint(_ readingListHint: ReadingListHintViewController, shouldBeHidden: Bool) {
        setHintHidden(shouldBeHidden)
    }
}

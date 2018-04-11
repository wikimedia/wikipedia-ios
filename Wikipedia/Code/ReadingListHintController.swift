import UIKit

@objc(WMFReadingListHintPresenter)
public protocol ReadingListHintPresenter: class {
    @objc var readingListHintController: ReadingListHintController? { get }
}

protocol ReadingListHintViewControllerDelegate: class {
    func readingListHint(_ readingListHint: ReadingListHintViewController, shouldBeHidden: Bool)
}

@objc(WMFReadingListHintController)
public class ReadingListHintController: NSObject, ReadingListHintViewControllerDelegate {

    private let dataStore: MWKDataStore
    private weak var presenter: UIViewController?
    private let hintVC: ReadingListHintViewController
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
        self.hintVC = ReadingListHintViewController()
        self.hintVC.dataStore = dataStore
        super.init()
        self.hintVC.delegate = self
    }
    
    func removeHint() {
        task?.cancel()
        hintVC.willMove(toParentViewController: nil)
        hintVC.view.removeFromSuperview()
        hintVC.removeFromParentViewController()
        resetHint()
    }
    
    func addHint() {
        hintVC.apply(theme: theme)
        presenter?.addChildViewController(hintVC)
        hintVC.view.autoresizingMask = [.flexibleTopMargin, .flexibleWidth]
        presenter?.view.addSubview(hintVC.view)
        hintVC.didMove(toParentViewController: presenter)
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
        let task = DispatchWorkItem { [weak self] in
            self?.setHintHidden(true)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + hintVisibilityTime , execute: task)
        self.task = task
    }
    
    @objc func setHintHidden(_ hintHidden: Bool) {
        let frame = hintHidden ? hintFrame.hidden : hintFrame.visible
        if !hintHidden {
            // add hint before animation starts
            addHint()
            // set initial frame
            if hintVC.view.frame.origin.y == 0 {
                hintVC.view.frame = hintFrame.hidden
            }
        }
        
        updateRandom(hintHidden)
        
        UIView.animate(withDuration: 0.4, delay: 0, options: [.curveEaseInOut, .beginFromCurrentState], animations: {
            self.hintVC.view.frame = frame
            self.hintVC.view.setNeedsLayout()
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
        guard presenter?.presentedViewController == nil else {
            return
        }

        didSaveArticle = didSave
        self.theme = theme
        
        let didSaveOtherArticle = didSave && !isHintHidden && article != hintVC.article
        let didUnsaveOtherArticle = !didSave && !isHintHidden && article != hintVC.article
        
        guard !didUnsaveOtherArticle else {
            return
        }
        
        guard !didSaveOtherArticle else {
            resetHint()
            dismissHint()
            hintVC.article = article
            return
        }
        
        hintVC.article = article
        setHintHidden(!didSave)
    }
    
    private func resetHint() {
        didSaveArticle = false
        hintVisibilityTime = 13
        hintVC.reset()
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

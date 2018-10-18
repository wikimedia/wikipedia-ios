import UIKit

@objc(WMFReadingListHintPresenter)
public protocol ReadingListHintPresenter: class {
    @objc var readingListHintController: ReadingListHintController? { get }
}

protocol ReadingListHintViewControllerDelegate: class {
    func readingListHint(_ readingListHint: ReadingListHintViewController, shouldBeHidden: Bool)
    func readingListHintHeightChanged()
}

@objc(WMFReadingListHintController)
public class ReadingListHintController: NSObject, ReadingListHintViewControllerDelegate {

    private let dataStore: MWKDataStore
    private weak var presenter: UIViewController?
    private let hintVC: ReadingListHintViewController
    private var theme: Theme = Theme.standard
    private var didSaveArticle: Bool = false
    private var containerView = UIView()
    
    private func isHintHidden() -> Bool {
        return self.containerView.superview == nil
    }
        
    @objc init(dataStore: MWKDataStore, presenter: UIViewController) {
        self.dataStore = dataStore
        self.presenter = presenter
        self.hintVC = ReadingListHintViewController()
        self.hintVC.dataStore = dataStore
        super.init()
        self.hintVC.delegate = self
    }
    
    private func removeHint() {
        task?.cancel()
        hintVC.willMove(toParent: nil)
        hintVC.view.removeFromSuperview()
        hintVC.removeFromParent()
        containerView.removeFromSuperview()
        resetHint()
    }
    
    private var containerBottomConstraint:NSLayoutConstraint?
    private var containerTopConstraint:NSLayoutConstraint?
    
    private func addHint() {
        guard isHintHidden() else {
            return
        }
        hintVC.apply(theme: theme)
        
        containerView.translatesAutoresizingMaskIntoConstraints = false

        presenter?.view.addSubview(containerView)
        
        if let presenter = presenter {
            let safeBottomAnchor = presenter.view.safeAreaLayoutGuide.bottomAnchor

            // `containerBottomConstraint` is activated when the hint is visible
            containerBottomConstraint = containerView.bottomAnchor.constraint(equalTo: safeBottomAnchor)
            containerBottomConstraint?.isActive = false

            // `containerTopConstraint` is activated when the hint is hidden
            containerTopConstraint = containerView.topAnchor.constraint(equalTo: safeBottomAnchor)
            
            let leadingConstraint = containerView.leadingAnchor.constraint(equalTo: presenter.view.leadingAnchor)
            let trailingConstraint = containerView.trailingAnchor.constraint(equalTo: presenter.view.trailingAnchor)
            NSLayoutConstraint.activate([containerTopConstraint!, leadingConstraint, trailingConstraint])
            
            if presenter.isKind(of: SearchResultsViewController.self){
                presenter.wmf_hideKeyboard()
            }
        } else {
            assertionFailure("Expected presenter")
        }
        
        hintVC.view.setContentHuggingPriority(.required, for: .vertical)
        containerView.setContentHuggingPriority(.required, for: .vertical)
        hintVC.view.setContentCompressionResistancePriority(.required, for: .vertical)
        containerView.setContentCompressionResistancePriority(.required, for: .vertical)
        
        presenter?.wmf_add(childController: hintVC, andConstrainToEdgesOfContainerView: containerView)
    }
    
    private var hintVisibilityTime: TimeInterval = 13 {
        didSet {
            guard hintVisibilityTime != oldValue else {
                return
            }
            dismissHint()
        }
    }
    
    private var task: DispatchWorkItem?
    
    private func updateRandom(_ hintHidden: Bool) {
        if let navigationController = (presenter as? WMFRandomArticleViewController)?.navigationController as? WMFArticleNavigationController {
            navigationController.readingListHintHeight = containerView.frame.size.height
            navigationController.readingListHintHidden = hintHidden
        }
    }
    
    private func dismissHint() {
        self.task?.cancel()
        let task = DispatchWorkItem { [weak self] in
            self?.setHintHidden(true)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + hintVisibilityTime , execute: task)
        self.task = task
    }
    
    @objc func setHintHidden(_ hintHidden: Bool) {
        guard isHintHidden() != hintHidden else {
            return
        }
        
        if !hintHidden {
            // add hint before animation starts
            addHint()
            
            containerView.superview?.layoutIfNeeded()
        }
        
        updateRandom(hintHidden)
        
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut], animations: {
            if hintHidden {
                self.containerBottomConstraint?.isActive = false
                self.containerTopConstraint?.isActive = true
            } else {
                self.containerBottomConstraint?.isActive = true
                self.containerTopConstraint?.isActive = false
            }
            self.containerView.superview?.layoutIfNeeded()
        }, completion: { (_) in
            // remove hint after animation is completed
            if hintHidden {
                self.updateRandom(hintHidden)
                self.removeHint()
            }else{
                self.dismissHint()
            }
        })
    }
    
    @objc func didSave(_ didSave: Bool, article: WMFArticle, theme: Theme) {
        guard presenter?.presentedViewController == nil else {
            return
        }

        didSaveArticle = didSave
        self.theme = theme
        
        let didSaveOtherArticle = didSave && !isHintHidden() && article != hintVC.article
        let didUnsaveOtherArticle = !didSave && !isHintHidden() && article != hintVC.article
        
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
        guard !isHintHidden() else {
            return
        }
        hintVisibilityTime = 0
    }
    
    // MARK: - ReadingListHintViewControllerDelegate
    
    func readingListHint(_ readingListHint: ReadingListHintViewController, shouldBeHidden: Bool) {
        setHintHidden(shouldBeHidden)
    }
    
    func readingListHintHeightChanged(){
        updateRandom(isHintHidden())
    }
}

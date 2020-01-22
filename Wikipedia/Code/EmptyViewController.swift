import Foundation
import WMF

protocol EmptyViewControllerDelegate: AnyObject {
    func triggeredRefresh(refreshCompletion: @escaping () -> Void)
    func emptyViewScrollViewDidScroll(_ scrollView: UIScrollView)
}

class EmptyViewController: UIViewController {
    private let refreshControl = UIRefreshControl()
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var emptyContainerView: UIView!
    private var emptyView: WMFEmptyView? = nil
    var canRefresh: Bool = false
    weak var delegate: EmptyViewControllerDelegate?
    var theme: Theme = .standard
    @IBOutlet var emptyContainerViewTopConstraint: NSLayoutConstraint!
    
    var type: WMFEmptyViewType? {
        didSet {
            if oldValue != type {
                emptyView?.removeFromSuperview()
                emptyView = nil
                
                if let newType = type,
                    let emptyView = EmptyViewController.emptyView(of: newType, theme: self.theme, frame: .zero) {
                    emptyView.delegate = self
                    emptyContainerView.wmf_addSubviewWithConstraintsToEdges(emptyView)

                    self.emptyView = emptyView
                    apply(theme: theme)
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.delegate = self
        scrollView.alwaysBounceVertical = true
        scrollView.contentInsetAdjustmentBehavior = .never
        
        if (canRefresh) {
            refreshControl.layer.zPosition = -100
            refreshControl.addTarget(self, action: #selector(refreshControlActivated), for: .valueChanged)
            
            scrollView.addSubview(refreshControl)
            scrollView.refreshControl = refreshControl
        }
        
        apply(theme: theme)
    }
    
    @objc private func refreshControlActivated() {
        
        delegate?.triggeredRefresh(refreshCompletion: { [weak self] in
            self?.refreshControl.endRefreshing()
        })
    }
    
    func centerEmptyView(topInset: CGFloat, topEmptyViewSpacing: CGFloat) {
        guard viewIfLoaded != nil else {
            return
        }
        scrollView.contentInset = UIEdgeInsets(top: topInset, left: 0, bottom: 0, right: 0)
        emptyContainerViewTopConstraint.constant = topEmptyViewSpacing
    }
    
    func centerEmptyView(within targetRect: CGRect) {
        scrollView.contentInset = UIEdgeInsets(top: targetRect.minY, left: 0, bottom: 0, right: 0)
    }
    
    private func determineTopOffset(emptyViewHeight: CGFloat) {
        let availableHeight = view.bounds.height - scrollView.contentInset.top
        let middle = availableHeight/2
        let heightMiddle = emptyViewHeight / 2
        let targetY = middle - heightMiddle
        emptyContainerViewTopConstraint.constant = max(0, ceil(targetY))
    }
}

extension EmptyViewController: Themeable {
    func apply(theme: Theme) {
        
        self.theme = theme
        
        guard viewIfLoaded != nil else {
            return
        }
        
        if let emptyView = emptyView,
            let bgKeyPath = theme.value(forKeyPath: emptyView.backgroundColorKeyPath) as? UIColor {
            view.backgroundColor = bgKeyPath
            scrollView.backgroundColor = bgKeyPath
            (emptyView as Themeable).apply(theme: theme)
        } else {
            view.backgroundColor = theme.colors.paperBackground
            scrollView.backgroundColor = theme.colors.paperBackground
        }
        
        refreshControl.tintColor = theme.colors.refreshControlTint
    }
}

extension EmptyViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        delegate?.emptyViewScrollViewDidScroll(scrollView)
    }
}

extension EmptyViewController: WMFEmptyViewDelegate {
    func heightChanged(_ height: CGFloat) {
        determineTopOffset(emptyViewHeight: height)
    }
}

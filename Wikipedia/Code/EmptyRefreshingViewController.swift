import Foundation

protocol EmptyRefreshingViewControllerDelegate: class {
    func triggeredRefresh(refreshCompletion: @escaping () -> Void)
}

class EmptyRefreshingViewController: ViewController {
    private let refreshControl = UIRefreshControl()
    private var emptyView: WMFEmptyView? = nil
    weak var delegate: EmptyRefreshingViewControllerDelegate?
    
    var type: WMFEmptyViewType? {
        didSet {
            if oldValue != type {
                emptyView?.removeFromSuperview()
                emptyView = nil
                
                if let newType = type,
                    let emptyView = EmptyRefreshingViewController.emptyView(of: newType, theme: self.theme, frame: view.bounds) {
                    scrollView?.addSubview(emptyView)
                    self.emptyView = emptyView
                }
            }
        }
    }
    
    override init() {

        super.init()
        
        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        view.wmf_addSubviewWithConstraintsToEdges(scrollView)
        self.scrollView = scrollView
        
        refreshControl.layer.zPosition = -100
        refreshControl.addTarget(self, action: #selector(refreshControlActivated), for: .valueChanged)
        
        scrollView.addSubview(refreshControl)
        scrollView.refreshControl = refreshControl
        
    }
    
    @objc private func refreshControlActivated() {
        
        delegate?.triggeredRefresh(refreshCompletion: { [weak self] in
            self?.refreshControl.endRefreshing()
        })
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        
        view.backgroundColor = theme.colors.paperBackground
        scrollView?.backgroundColor = theme.colors.paperBackground
        refreshControl.tintColor = theme.colors.refreshControlTint
        if let emptyView = emptyView {
            EmptyRefreshingViewController.wmf_applyTheme(to: emptyView, with: theme)
        }
        
    }
}

import Foundation

protocol EmptyViewControllerDelegate: AnyObject {
    func triggeredRefresh(refreshCompletion: @escaping () -> Void)
    func emptyViewScrollViewDidScroll(_ scrollView: UIScrollView)
}

class EmptyViewController: UIViewController {
    private let refreshControl = UIRefreshControl()
    private var emptyView: WMFEmptyView? = nil
    private let scrollView = UIScrollView()
    private var canRefresh: Bool
    weak var delegate: EmptyViewControllerDelegate?
    private var theme: Theme = .light
    
    var type: WMFEmptyViewType? {
        didSet {
            if oldValue != type {
                emptyView?.removeFromSuperview()
                emptyView = nil
                
                if let newType = type,
                    let emptyView = EmptyViewController.emptyView(of: newType, theme: self.theme, frame: .zero) {
                    emptyView.translatesAutoresizingMaskIntoConstraints = false
                    scrollView.wmf_addSubviewWithConstraintsToEdges(emptyView)
                    view.widthAnchor.constraint(equalTo: emptyView.widthAnchor, multiplier: 1).isActive = true
                    self.emptyView = emptyView
                    apply(theme: theme)
                }
            }
        }
    }
    
    init(canRefresh: Bool, theme: Theme) {
        self.canRefresh = canRefresh
        super.init(nibName: nil, bundle: nil)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        apply(theme: theme)
    }
    
    private func commonInit() {

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        scrollView.delegate = self
        view.wmf_addSubviewWithConstraintsToEdges(scrollView)
        
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
    
    func setContentInset(inset: UIEdgeInsets) {
        scrollView.contentInset = inset
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

import WMF

extension UIViewController {
    @objc class func wmf_viewControllerFromReferencePanelsStoryboard() -> Self {
        return self.wmf_viewControllerFromStoryboardNamed("WMFReferencePanels")
    }
}

protocol WMFReferencePageViewAppearanceDelegate : NSObjectProtocol {
    func referencePageViewControllerWillAppear(_ referencePageViewController: WMFReferencePageViewController)
    func referencePageViewControllerWillDisappear(_ referencePageViewController: WMFReferencePageViewController)
}

extension WMFReferencePageViewAppearanceDelegate where Self: ArticleScrolling {
    func referencePageViewControllerWillAppear(_ referencePageViewController: WMFReferencePageViewController) {
        guard
            let firstRefVC = referencePageViewController.pageViewController.viewControllers?.first as? WMFReferencePanelViewController,
            let refId = firstRefVC.reference?.refId
            else {
                return
        }
        webView.wmf_unHighlightAllLinkIDs()
        webView.wmf_highlightLinkID(refId)
    }

    func referencePageViewControllerWillDisappear(_ referencePageViewController: WMFReferencePageViewController) {
        webView.wmf_unHighlightAllLinkIDs()
    }
}

extension UIPageViewControllerDelegate where Self: ArticleScrolling & ViewController {
    /// This function needs to be called by `pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool)`. Due to objc issues, the delegate's cannot have a default extension with this actual method that is called.
    func didFinishAnimating(_ pageViewController: UIPageViewController) {
        guard
            let firstRefVC = pageViewController.viewControllers?.first as? WMFReferencePanelViewController,
            let ref = firstRefVC.reference
            else {
                return
        }
        (presentedViewController as? WMFReferencePageViewController)?.currentReference = ref
        webView.wmf_unHighlightAllLinkIDs()
        webView.wmf_highlightLinkID(ref.refId)
    }
}

class WMFReferencePageViewController: ReferenceViewController, UIPageViewControllerDataSource {
    @objc var lastClickedReferencesIndex:Int = 0
    @objc var lastClickedReferencesGroup = [WMFLegacyReference]()
    weak internal var appearanceDelegate: WMFReferencePageViewAppearanceDelegate?
    
    @objc public var pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    @IBOutlet fileprivate var containerView: UIView!
    
    var articleURL: URL?

    override func apply(theme: Theme) {
        super.apply(theme: theme)
        guard viewIfLoaded != nil else {
            return
        }
        backgroundView.apply(theme: theme)

    }

    fileprivate lazy var pageControllers: [UIViewController] = {
        var controllers:[UIViewController] = []
        
        for reference in self.lastClickedReferencesGroup {
            let panel = WMFReferencePanelViewController.wmf_viewControllerFromReferencePanelsStoryboard()
            panel.articleURL = articleURL
            panel.apply(theme: theme)
            panel.reference = reference
            controllers.append(panel)
        }
        
        return controllers
    }()
    
    @objc lazy var backgroundView: WMFReferencePageBackgroundView = {
        return WMFReferencePageBackgroundView()
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateReference(with: lastClickedReferencesIndex)
        
        addChild(pageViewController)
        pageViewController.view.frame = containerView.bounds
        pageViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        containerView.addSubview(pageViewController.view)
        pageViewController.didMove(toParent: self)
        
        pageViewController.dataSource = self
        
        let direction:UIPageViewController.NavigationDirection = UIApplication.shared.wmf_isRTL ? .forward : .reverse
        
        let initiallyVisibleController = pageControllers[lastClickedReferencesIndex]
        
        pageViewController.setViewControllers([initiallyVisibleController], direction: direction, animated: true, completion: nil)
        
        addBackgroundView()

        if let scrollView = view.wmf_firstSubviewOfType(UIScrollView.self) {
            scrollView.clipsToBounds = false
        }
        
        apply(theme: theme)
        accessibilityElements = [backToReferenceButton as Any, navigationItem.title as Any, closeButton as Any, pageControllers as Any]
    }
    
    fileprivate func addBackgroundView() {
        view.wmf_addSubviewWithConstraintsToEdges(backgroundView)
        view.sendSubviewToBack(backgroundView)
    }
    
    @objc internal func firstPanelView() -> UIView? {
        guard let viewControllers = pageViewController.viewControllers, let firstVC = viewControllers.first as? WMFReferencePanelViewController else {
            return nil
        }
        return firstVC.containerView
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        appearanceDelegate?.referencePageViewControllerWillAppear(self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        appearanceDelegate?.referencePageViewControllerWillDisappear(self)
    }
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return pageControllers.count
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        guard let viewControllers = pageViewController.viewControllers, let currentVC = viewControllers.first, let presentationIndex = pageControllers.firstIndex(of: currentVC) else {
            return 0
        }
        return presentationIndex
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = pageControllers.firstIndex(of: viewController) else {
            return nil
        }
        return index >= pageControllers.count - 1 ? nil : pageControllers[index + 1]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = pageControllers.firstIndex(of: viewController) else {
            return nil
        }
        return index == 0 ? nil : pageControllers[index - 1]
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        self.presentingViewController?.dismiss(animated: false, completion: nil)
    }
    
    func updateReference(with index: Int) {
        guard index < lastClickedReferencesGroup.count else {
            return
        }
        currentReference = lastClickedReferencesGroup[index]
    }
    
    var currentReference: WMFLegacyReference? = nil {
        didSet {
            referenceId = currentReference?.anchor.removingPercentEncoding
            referenceLinkText = currentReference?.text
        }
    }
    
}

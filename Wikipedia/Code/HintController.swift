@objc(WMFHintPresenting)
protocol HintPresenting: AnyObject {
    var hintController: HintController? { get set }
}

class HintController: NSObject {
    typealias Context = [String: Any]

    typealias HintPresentingViewController = UIViewController & HintPresenting
    private weak var presenter: HintPresentingViewController?
    
    private let hintViewController: HintViewController

    private var containerView = UIView()
    private var containerViewConstraint: (top: NSLayoutConstraint?, bottom: NSLayoutConstraint?)

    private var task: DispatchWorkItem?

    var theme = Theme.standard
    
    // if true, hint will extend below safe area to the bottom of the view, and hint content within will align to safe area
    // must also override extendsUnderSafeArea to true in HintViewController
    var extendsUnderSafeArea: Bool {
        return false
    }

    init(hintViewController: HintViewController) {
        self.hintViewController = hintViewController
        super.init()
        hintViewController.delegate = self
    }

    var isHintHidden: Bool {
        return containerView.superview == nil
    }

    private var hintVisibilityTime: TimeInterval = 13 {
        didSet {
            guard hintVisibilityTime != oldValue else {
                return
            }
            dismissHint()
        }
    }

    func dismissHint(completion: (() -> Void)? = nil) {
        self.task?.cancel()
        let task = DispatchWorkItem { [weak self] in
            self?.setHintHidden(true)
            if let completion = completion {
                completion()
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + hintVisibilityTime , execute: task)
        self.task = task
    }

    @objc func toggle(presenter: HintPresentingViewController, context: Context?, theme: Theme) {
        self.presenter = presenter
        apply(theme: theme)
    }

    func toggle(presenter: HintPresentingViewController, context: Context?, theme: Theme, subview: UIView? = nil, additionalBottomSpacing: CGFloat = 0, setPrimaryColor: ((inout UIColor?) -> Void)? = nil, setBackgroundColor: ((inout UIColor?) -> Void)? = nil) {
        self.subview = subview
        self.additionalBottomSpacing = additionalBottomSpacing
        setPrimaryColor?(&hintViewController.primaryColor)
        setBackgroundColor?(&hintViewController.backgroundColor)
        self.presenter = presenter
        apply(theme: theme)
    }

    private var subview: UIView?
    private var additionalBottomSpacing: CGFloat = 0

    private func addHint(to presenter: HintPresentingViewController) {
        guard isHintHidden else {
            return
        }

        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        var bottomAnchor: NSLayoutYAxisAnchor = extendsUnderSafeArea ? presenter.view.bottomAnchor : presenter.view.safeAreaLayoutGuide.bottomAnchor
        
        if let wmfVCPresenter = presenter as? ViewController { // not ideal, violates encapsulation
            wmfVCPresenter.view.insertSubview(containerView, belowSubview: wmfVCPresenter.toolbar)
            if !wmfVCPresenter.isToolbarHidden && wmfVCPresenter.toolbar.superview != nil {
                bottomAnchor = wmfVCPresenter.toolbar.topAnchor
            }
        } else if let subview = subview {
            presenter.view.insertSubview(containerView, belowSubview: subview)
        } else {
            presenter.view.addSubview(containerView)
        }

        // `containerBottomConstraint` is activated when the hint is visible
        containerViewConstraint.bottom = containerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0 - additionalBottomSpacing)

        // `containerTopConstraint` is activated when the hint is hidden
        containerViewConstraint.top = containerView.topAnchor.constraint(equalTo: bottomAnchor)

        let leadingConstraint = containerView.leadingAnchor.constraint(equalTo: presenter.view.leadingAnchor)
        let trailingConstraint = containerView.trailingAnchor.constraint(equalTo: presenter.view.trailingAnchor)

        NSLayoutConstraint.activate([containerViewConstraint.top!, leadingConstraint, trailingConstraint])

        if presenter.isKind(of: SearchResultsViewController.self) {
            presenter.wmf_hideKeyboard()
        }

        hintViewController.view.setContentHuggingPriority(.required, for: .vertical)
        hintViewController.view.setContentCompressionResistancePriority(.required, for: .vertical)
        containerView.setContentHuggingPriority(.required, for: .vertical)
        containerView.setContentCompressionResistancePriority(.required, for: .vertical)

        presenter.wmf_add(childController: hintViewController, andConstrainToEdgesOfContainerView: containerView)

        containerView.superview?.layoutIfNeeded()
    }

    private func removeHint() {
        task?.cancel()
        hintViewController.willMove(toParent: nil)
        hintViewController.view.removeFromSuperview()
        hintViewController.removeFromParent()
        containerView.removeFromSuperview()
        resetHint()
    }

    func resetHint() {
        hintVisibilityTime = 13
        hintViewController.viewType = .default
    }

    func setHintHidden(_ hidden: Bool, completion: (() -> Void)? = nil) {        
        guard
            isHintHidden != hidden,
            let presenter = presenter,
            presenter.presentedViewController == nil
        else {
            if let completion = completion {
                completion()
            }
            return
        }

        presenter.hintController = self

        if !hidden {
            // add hint before animation starts
            addHint(to: presenter)
        }

        self.adjustSpacingIfPresenterHasSecondToolbar(hintHidden: hidden)

        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut], animations: {
            if hidden {
                self.containerViewConstraint.bottom?.isActive = false
                self.containerViewConstraint.top?.isActive = true
            } else {
                self.containerViewConstraint.top?.isActive = false
                self.containerViewConstraint.bottom?.isActive = true
            }
            self.containerView.superview?.layoutIfNeeded()
        }, completion: { (_) in
            // remove hint after animation is completed
            if hidden {
                self.adjustSpacingIfPresenterHasSecondToolbar(hintHidden: hidden)
                self.removeHint()
                if let completion = completion {
                    completion()
                }
            } else {
                self.dismissHint(completion: completion)
            }
        })
    }

    @objc func dismissHintDueToUserInteraction() {
        guard !self.isHintHidden else {
            return
        }
        self.hintVisibilityTime = 0
    }

    private func adjustSpacingIfPresenterHasSecondToolbar(hintHidden: Bool) {
        guard
            let viewController = presenter as? ViewController,
            !viewController.isSecondToolbarHidden && !hintHidden
        else {
            return
        }
        viewController.setSecondToolbarHidden(true, animated: true)
    }
}

extension HintController: HintViewControllerDelegate {
    func hintViewControllerWillDisappear(_ hintViewController: HintViewController) {
        setHintHidden(true)
    }

    func hintViewControllerHeightDidChange(_ hintViewController: HintViewController) {
        adjustSpacingIfPresenterHasSecondToolbar(hintHidden: isHintHidden)
    }

    func hintViewControllerViewTypeDidChange(_ hintViewController: HintViewController, newViewType: HintViewController.ViewType) {
        guard newViewType == .confirmation else {
            return
        }
        setHintHidden(false)
    }

    func hintViewControllerDidPeformConfirmationAction(_ hintViewController: HintViewController) {
        setHintHidden(true)
    }

    func hintViewControllerDidFailToCompleteDefaultAction(_ hintViewController: HintViewController) {
        setHintHidden(true)
    }
}

extension HintController: Themeable {
    func apply(theme: Theme) {
        hintViewController.apply(theme: theme)
    }
}

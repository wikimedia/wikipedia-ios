@objc(WMFHintPresenting)
protocol HintPresenting: AnyObject {
    var scrollViewWillBeginDraggingCompletion: (() -> Void)? { get set }
}

class HintController: NSObject {
    typealias HintPresentingViewController = UIViewController & HintPresenting

    @objc weak var presenter: HintPresentingViewController?
    
    private let hintViewController: HintViewController

    private var containerView = UIView()
    private var containerViewConstraint: (top: NSLayoutConstraint?, bottom: NSLayoutConstraint?)

    private var task: DispatchWorkItem?

    var theme = Theme.standard

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

    func dismissHint() {
        self.task?.cancel()
        let task = DispatchWorkItem { [weak self] in
            self?.setHintHidden(true)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + hintVisibilityTime , execute: task)
        self.task = task
    }

    private func addHint() {
    private func addHint(to presenter: HintPresentingViewController) {
        guard isHintHidden else {
            return
        }

        containerView.translatesAutoresizingMaskIntoConstraints = false

        var additionalBottomSpacing: CGFloat = 0

        if let wmfVCPresenter = presenter as? WMFViewController { // not ideal, violates encapsulation
            wmfVCPresenter.view.insertSubview(containerView, belowSubview: wmfVCPresenter.toolbar)
            additionalBottomSpacing = wmfVCPresenter.toolbar.frame.size.height
        } else {
            presenter.view.addSubview(containerView)
        }

        let safeBottomAnchor = presenter.view.safeAreaLayoutGuide.bottomAnchor

        // `containerBottomConstraint` is activated when the hint is visible
        containerViewConstraint.bottom = containerView.bottomAnchor.constraint(equalTo: safeBottomAnchor, constant: 0 - additionalBottomSpacing)

        // `containerTopConstraint` is activated when the hint is hidden
        containerViewConstraint.top = containerView.topAnchor.constraint(equalTo: safeBottomAnchor)

        let leadingConstraint = containerView.leadingAnchor.constraint(equalTo: presenter.view.leadingAnchor)
        let trailingConstraint = containerView.trailingAnchor.constraint(equalTo: presenter.view.trailingAnchor)

        NSLayoutConstraint.activate([containerViewConstraint.top!, leadingConstraint, trailingConstraint])

        if presenter.isKind(of: SearchResultsViewController.self){
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

    func setHintHidden(_ hintHidden: Bool) {
        guard
            isHintHidden != hintHidden,
            let presenter = presenter,
            presenter.presentedViewController == nil
        else {
            return
        }

        makePresenterReportScrollIfNeeded(presenter)

        if !hintHidden {
            // add hint before animation starts
            addHint(to: presenter)
        }

        updateRandom(hintHidden)

        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut], animations: {
            if hintHidden {
                self.containerViewConstraint.bottom?.isActive = false
                self.containerViewConstraint.top?.isActive = true
            } else {
                self.containerViewConstraint.top?.isActive = false
                self.containerViewConstraint.bottom?.isActive = true
            }
            self.containerView.superview?.layoutIfNeeded()
        }, completion: { (_) in
            // remove hint after animation is completed
            if hintHidden {
                self.updateRandom(hintHidden)
                self.removeHint()
            } else {
                self.dismissHint()
            }
        })
    }

    private func updateRandom(_ hintHidden: Bool) {
        if let vc = presenter as? WMFRandomArticleViewController {
            vc.setAdditionalSecondToolbarSpacing(hintHidden ? 0 : containerView.frame.height, animated: true)
        }
    }

    private func makePresenterReportScrollIfNeeded(_ presenter: HintPresentingViewController) {
        presenter.scrollViewWillBeginDraggingCompletion = {
            guard !self.isHintHidden else {
                return
            }
            self.hintVisibilityTime = 0
        }
    }
}

extension HintController: HintViewControllerDelegate {
    func hintViewControllerWillDisappear(_ hintViewController: HintViewController) {
        setHintHidden(true)
    }

    func hintViewControllerHeightDidChange(_ hintViewController: HintViewController) {
        updateRandom(isHintHidden)
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

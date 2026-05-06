import UIKit
import SwiftUI

@MainActor
final public class WMFReadingListToastPresenter {

    // MARK: - Properties

    private weak var presenter: UIViewController?

    private var currentToastContainer: UIView?
    private var currentHostingController: UIHostingController<WMFReadingListToastView>?
    private var currentModel: WMFReadingListToastModel?
    /// Dedicated window that hosts the toast. Isolates the toast's
    /// UIHostingController from the key window's layout cycle so the
    /// keyboard can appear without triggering a SwiftUI layout freeze.
    private var toastWindow: ToastPassthroughWindow?

    private var dismissWorkItem: DispatchWorkItem?

    private var subview: UIView?
    private var additionalBottomSpacing: CGFloat = 0
    private var extendsUnderSafeArea: Bool = false

    public init(presenter: UIViewController? = nil, currentToastContainer: UIView? = nil, currentHostingController: UIHostingController<WMFReadingListToastView>? = nil, currentModel: WMFReadingListToastModel? = nil, dismissWorkItem: DispatchWorkItem? = nil, subview: UIView? = nil) {
        self.presenter = presenter
        self.currentToastContainer = currentToastContainer
        self.currentHostingController = currentHostingController
        self.currentModel = currentModel
        self.dismissWorkItem = dismissWorkItem
        self.subview = subview
    }

    public var theme: WMFTheme {
        WMFAppEnvironment.current.theme
    }

    // MARK: - Public API

    public var isToastHidden: Bool {
        currentToastContainer?.superview == nil ||
        currentToastContainer?.window == nil // indicates it is on screen somewhere but not currently visible
    }

    /// Show a toast anchored to a specific view controller
    public func show(
        config: WMFReadingListToastConfig,
        in presenter: UIViewController,
        subview: UIView? = nil,
        additionalBottomSpacing: CGFloat = 0,
        extendsUnderSafeArea: Bool = false
    ) {
        // Update stored presenter each time to avoid anchoring to stale VCs.
        self.presenter = presenter
        self.subview = subview
        self.additionalBottomSpacing = additionalBottomSpacing
        self.extendsUnderSafeArea = extendsUnderSafeArea

        // If a toast is already visible, replace it in-place
        if !isToastHidden {
            updateCurrentToast(with: config)
            return
        }

        setToastHidden(false, config: config)
    }

    public func dismissToast() {
        guard !isToastHidden else { return }
        setToastHidden(true, config: nil)
    }

    /// Dismisses the toast immediately without animation.
    public func dismissToastImmediately() {
        guard !isToastHidden else { return }
        dismissWorkItem?.cancel()
        dismissWorkItem = nil
        currentHostingController?.view.removeFromSuperview()
        currentToastContainer?.removeFromSuperview()
        currentHostingController = nil
        currentToastContainer = nil
        currentModel = nil
        tearDownWindow()
    }

    public func resetToast() {
        dismissWorkItem?.cancel()
        dismissWorkItem = nil
    }

    public func updateCurrentToast(with config: WMFReadingListToastConfig) {
        currentModel?.config = config
        scheduleDismiss(config: config)
    }

    // MARK: - Private Methods

    private func setToastHidden(_ hidden: Bool, config: WMFReadingListToastConfig?, completion: (() -> Void)? = nil) {
        guard isToastHidden != hidden else {
            completion?()
            return
        }

        if hidden {
            dismissWorkItem?.cancel()
            dismissWorkItem = nil
        }

        if !hidden {
            guard let presenter, presenter.presentedViewController == nil else {
                completion?()
                return
            }
            guard let config else {
                completion?()
                return
            }
            addToast(to: presenter, config: config)
        }

        let container = currentToastContainer
        let translationY = (container?.frame.height ?? 100) + 50

        if hidden {
            UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseIn], animations: {
                container?.transform = CGAffineTransform(translationX: 0, y: translationY)
                container?.alpha = 0
            }, completion: { _ in
                self.removeToast()
                completion?()
            })
        } else {
            UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0.6, options: [.curveEaseOut], animations: {
                container?.transform = .identity
                container?.alpha = 1
            }, completion: { _ in
                self.scheduleDismiss(config: config)
                completion?()
            })
        }
    }

    // MARK: - Toast Window

    private func makeToastWindow() -> ToastPassthroughWindow? {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })
                ?? UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first
        else { return nil }

        let window = ToastPassthroughWindow(windowScene: scene)
        window.windowLevel = .normal + 1  // above normal but below alerts
        window.backgroundColor = .clear
        window.isUserInteractionEnabled = true

        // An invisible root VC is required for the window to display.
        let rootVC = UIViewController()
        rootVC.view.backgroundColor = .clear
        rootVC.view.isUserInteractionEnabled = true
        window.rootViewController = rootVC
        window.isHidden = false

        return window
    }

    private func tearDownWindow() {
        toastWindow?.isHidden = true
        toastWindow?.rootViewController = nil
        toastWindow = nil
    }

    // MARK: - Add / Remove Toast

    private func addToast(to outsidePresenter: UIViewController, config: WMFReadingListToastConfig) {
        guard isToastHidden else { return }

        guard let window = makeToastWindow(),
              let rootView = window.rootViewController?.view else {
            debugPrint("Could not create toast window")
            return
        }
        toastWindow = window

        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .clear
        containerView.transform = CGAffineTransform(translationX: 0, y: 200)
        containerView.alpha = 0

        rootView.addSubview(containerView)

        // Position above the tab bar / toolbar when visible, matching WMFToastPresenter.
        // We read the toolbar offset from the key window's rootViewController since
        // our toast window doesn't have a tab bar.
        let keyWindow = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })
        let toolbarOffset = keyWindow?.rootViewController?.visibleToolbarHeightAboveSafeArea() ?? 0

        let bottomConstant: CGFloat
        if toolbarOffset > 0 {
            bottomConstant = -(additionalBottomSpacing + 24 + toolbarOffset)
        } else {
            bottomConstant = -(additionalBottomSpacing + 24)
        }

        let anchor: NSLayoutYAxisAnchor = extendsUnderSafeArea
            ? rootView.bottomAnchor
            : rootView.safeAreaLayoutGuide.bottomAnchor

        NSLayoutConstraint.activate([
            containerView.bottomAnchor.constraint(equalTo: anchor, constant: bottomConstant),
            containerView.leadingAnchor.constraint(equalTo: rootView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: rootView.trailingAnchor)
        ])

        let model = WMFReadingListToastModel(config: config)
        currentModel = model

        let toastView = WMFReadingListToastView(model: model, dismiss: { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                self.setToastHidden(true, config: nil)
            }
        })

        let hostingController = UIHostingController(rootView: toastView)
        hostingController.view.backgroundColor = .clear
        hostingController.view.insetsLayoutMarginsFromSafeArea = false
        hostingController.view.layoutMargins = .zero
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.setContentHuggingPriority(.required, for: .vertical)
        hostingController.view.setContentCompressionResistancePriority(.required, for: .vertical)
        hostingController.sizingOptions = [.intrinsicContentSize]
        hostingController.safeAreaRegions = []

        let shadowContainer = UIView()
        shadowContainer.translatesAutoresizingMaskIntoConstraints = false
        shadowContainer.backgroundColor = .clear
        if #unavailable(iOS 26.0) {
            shadowContainer.layer.shadowColor = theme.toastShadow.cgColor
            shadowContainer.layer.shadowOffset = CGSize(width: 0, height: 8)
            shadowContainer.layer.shadowRadius = 16
            shadowContainer.layer.shadowOpacity = 1
        }

        shadowContainer.addSubview(hostingController.view)

        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: shadowContainer.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: shadowContainer.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: shadowContainer.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: shadowContainer.bottomAnchor)
        ])

        shadowContainer.setContentHuggingPriority(.required, for: .vertical)
        shadowContainer.setContentCompressionResistancePriority(.required, for: .vertical)

        containerView.addSubview(shadowContainer)

        let cardLeading = shadowContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16)
        let cardTrailing = shadowContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16)
        cardLeading.priority = .required
        cardTrailing.priority = .required

        NSLayoutConstraint.activate([
            cardLeading,
            cardTrailing,
            shadowContainer.topAnchor.constraint(equalTo: containerView.topAnchor),
            shadowContainer.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        if UIDevice.current.userInterfaceIdiom == .pad {
            let maxWidth: CGFloat = 400
            NSLayoutConstraint.activate([
                shadowContainer.widthAnchor.constraint(lessThanOrEqualToConstant: maxWidth),
                shadowContainer.centerXAnchor.constraint(equalTo: containerView.centerXAnchor)
            ])
        }

        containerView.setContentHuggingPriority(.required, for: .vertical)
        containerView.setContentCompressionResistancePriority(.required, for: .vertical)

        // Swipe down to dismiss
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleToastPan(_:)))
        containerView.addGestureRecognizer(panGesture)

        currentToastContainer = containerView
        currentHostingController = hostingController
    }
    
    @objc private func handleToastPan(_ gesture: UIPanGestureRecognizer) {
        guard let toast = gesture.view else { return }
        let translation = gesture.translation(in: toast.superview)

        switch gesture.state {
        case .changed:
            if translation.y > 0 {
                toast.transform = CGAffineTransform(translationX: 0, y: translation.y)
            }
        case .ended, .cancelled:
            let velocity = gesture.velocity(in: toast)
            let shouldDismiss = translation.y > 50 || velocity.y > 500

            if shouldDismiss {
                setToastHidden(true, config: nil)
            } else {
                UIView.animate(withDuration: 0.2) {
                    toast.transform = .identity
                }
            }
        default: break
        }
    }

    private func removeToast() {
        dismissWorkItem?.cancel()
        dismissWorkItem = nil

        currentHostingController?.view.removeFromSuperview()
        currentToastContainer?.removeFromSuperview()

        currentHostingController = nil
        currentToastContainer = nil
        currentModel = nil
        tearDownWindow()
    }

    private func scheduleDismiss(config: WMFReadingListToastConfig?) {
        dismissWorkItem?.cancel()
        dismissWorkItem = nil

        guard let config, let duration = config.duration else { return }

        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                self.setToastHidden(true, config: nil)
            }
        }
        dismissWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: workItem)
    }
}

// MARK: - Passthrough Window

/// A UIWindow that passes through all touches that don't hit the toast itself.
/// This prevents the toast window from stealing touches from the app below.
private final class ToastPassthroughWindow: UIWindow {
    /// Prevent this window from becoming key. If it becomes key the
    /// keyboard presentation routes through it and freezes the app.
    override var canBecomeKey: Bool { false }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hit = super.hitTest(point, with: event)
        // If the hit view is the window itself or the root VC's view,
        // the touch missed the toast — pass it through.
        if hit === self || hit === rootViewController?.view {
            return nil
        }
        return hit
    }
}

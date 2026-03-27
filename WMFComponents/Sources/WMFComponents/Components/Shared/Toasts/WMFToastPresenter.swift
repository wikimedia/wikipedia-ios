import UIKit
import SwiftUI
import Combine

@MainActor
public final class WMFToastPresenter {

    // MARK: - Nested Types

    public enum DismissEvent: Sendable {
        case tappedBackground
        case durationExpired
        case swipedDown
        case outsideEvent
    }

    // MARK: - Properties

    var appEnvironment: WMFAppEnvironment {
        return WMFAppEnvironment.current
    }

    var theme: WMFTheme {
        return WMFAppEnvironment.current.theme
    }

    private var cancellables = Set<AnyCancellable>()

    private var currentToast: UIView?
    private var backgroundTapGestureRecognizer: UITapGestureRecognizer?
    private var dismissWorkItem: DispatchWorkItem?
    private var dismissAction: (@Sendable (DismissEvent) -> Void)?
    /// True while the current toast's dismiss animation is running.
    private var isDismissing: Bool = false

    // MARK: - Lifecycle

    public static let shared = WMFToastPresenter()

    private init() {
        subscribeToAppEnvironmentChanges()
    }

    // MARK: - AppEnvironment Subscription

    private func subscribeToAppEnvironmentChanges() {
        WMFAppEnvironment.publisher
            .sink(receiveValue: { [weak self] _ in self?.appEnvironmentDidChange() })
            .store(in: &cancellables)
    }

    // MARK: - Subclass Overrides

    public func appEnvironmentDidChange() {
        if #available(iOS 26.0, *) {
            // Glass effect handles its own appearance on iOS 26+
            return
        }
        currentToast?.backgroundColor = theme.paperBackground
        currentToast?.layer.shadowColor = theme.toastShadow.cgColor

        if let borderLayer = currentToast?.layer.sublayers?.first(where: { $0.borderWidth > 0 }) {
            borderLayer.borderColor = theme.border.withAlphaComponent(0.15).cgColor
        }
    }

    // MARK: - Public API.
    public func show(_ config: WMFToastConfig) {
        let toastView = WMFToastView(config: config, dismiss: { [weak self] in
            self?.dismissCurrentToast()
        })
        presentToastView(view: toastView, duration: config.duration)
    }

    /// Presents a SwiftUI view as a toast at the bottom of the screen.
    public func presentToastView<Content: View>(
        view: Content,
        duration: TimeInterval? = nil,
        allowsBackgroundTapToDismiss: Bool = false,
        dismissAction: (@Sendable (DismissEvent) -> Void)? = nil
    ) {
        guard let containerView = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) else {
            debugPrint("No key window available")
            return
        }

        // Cancel any pending auto-dismiss for the outgoing toast.
        dismissWorkItem?.cancel()
        dismissWorkItem = nil
        self.dismissAction = dismissAction

        // Build the new toast view before any animation so it's ready to go.
        let toastContent = view
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)

        let hostingController = UIHostingController(rootView: toastContent)
        hostingController.view.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false

        let shadowContainer = UIView()
        shadowContainer.translatesAutoresizingMaskIntoConstraints = false
        shadowContainer.backgroundColor = .clear
        shadowContainer.layer.shadowColor = theme.toastShadow.cgColor
        shadowContainer.layer.shadowOffset = CGSize(width: 0, height: 8)
        shadowContainer.layer.shadowRadius = 16
        shadowContainer.layer.shadowOpacity = 1

        shadowContainer.addSubview(hostingController.view)

        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: shadowContainer.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: shadowContainer.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: shadowContainer.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: shadowContainer.bottomAnchor)
        ])

        // Start fully off-screen and invisible BEFORE entering the view hierarchy
        // so there is no flash on the frame the view is first added.
        shadowContainer.transform = CGAffineTransform(translationX: 0, y: 200)
        shadowContainer.alpha = 0

        // How long to wait before animating in the new toast.
        // If there's an existing toast on screen we animate it out first (0.25 s),
        // then slide the new one in. If the screen is clear we start immediately.
        let animateInDelay: TimeInterval

        if let outgoing = currentToast {
            let outgoingView = outgoing
            let translationY = outgoingView.frame.height + 50
            UIView.animate(
                withDuration: 0.25,
                delay: 0,
                options: [.curveEaseIn],
                animations: {
                    outgoingView.transform = CGAffineTransform(translationX: 0, y: translationY)
                    outgoingView.alpha = 0
                },
                completion: { _ in
                    outgoingView.removeFromSuperview()
                    if let backgroundTapGestureRecognizer = self.backgroundTapGestureRecognizer {
                        backgroundTapGestureRecognizer.view?.removeGestureRecognizer(backgroundTapGestureRecognizer)
                        self.backgroundTapGestureRecognizer = nil
                    }
                }
            )
            animateInDelay = 0.25
        } else {
            animateInDelay = 0
        }

        containerView.addSubview(shadowContainer)
        currentToast = shadowContainer

        // Position constraints
        let leading = shadowContainer.leadingAnchor.constraint(
            equalTo: containerView.safeAreaLayoutGuide.leadingAnchor,
            constant: 16
        )
        let trailing = shadowContainer.trailingAnchor.constraint(
            equalTo: containerView.safeAreaLayoutGuide.trailingAnchor,
            constant: -16
        )
        let toolbarOffset = containerView.rootViewController?.visibleToolbarHeightAboveSafeArea() ?? 0
        // When a tab bar or toolbar is present, offset above it with extra spacing.
        // When neither is present, pin closer to the bottom of the safe area.
        let bottomConstant: CGFloat
        if toolbarOffset > 0 {
            bottomConstant = -(24 + toolbarOffset + 8)
        } else {
            bottomConstant = 0
        }
        let bottom = shadowContainer.bottomAnchor.constraint(
            equalTo: containerView.safeAreaLayoutGuide.bottomAnchor,
            constant: bottomConstant
        )

        leading.priority = .required
        trailing.priority = .required
        bottom.priority = .required

        NSLayoutConstraint.activate([leading, trailing, bottom])

        if UIDevice.current.userInterfaceIdiom == .pad {
            let maxWidth: CGFloat = 400
            NSLayoutConstraint.activate([
                shadowContainer.widthAnchor.constraint(lessThanOrEqualToConstant: maxWidth),
                shadowContainer.centerXAnchor.constraint(equalTo: containerView.centerXAnchor)
            ])
        }

        UIView.animate(
            withDuration: 0.35,
            delay: animateInDelay,
            usingSpringWithDamping: 0.85,
            initialSpringVelocity: 0.6,
            options: [.curveEaseOut],
            animations: {
                shadowContainer.transform = .identity
                shadowContainer.alpha = 1
            }
        )

        // Background tap to dismiss
        if allowsBackgroundTapToDismiss {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleContainerTap(_:)))
            tapGesture.cancelsTouchesInView = false
            containerView.addGestureRecognizer(tapGesture)
            self.backgroundTapGestureRecognizer = tapGesture
        }

        // Swipe down to dismiss
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleToastPan(_:)))
        shadowContainer.addGestureRecognizer(panGesture)

        // Auto-dismiss
        if let duration, duration > 0 {
            let workItem = DispatchWorkItem { [weak self, weak shadowContainer] in
                guard let shadowContainer else { return }
                self?.dismissToast(shadowContainer, dismissEvent: .durationExpired)
            }
            dismissWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: workItem)
        }
    }

    public func dismissCurrentToast(completion: (() -> Void)? = nil) {
        guard let toast = currentToast else {
            completion?()
            return
        }

        if let completion {
            let existing = dismissAction
            dismissAction = { event in
                existing?(event)
                completion()
            }
        }
        dismissToast(toast, dismissEvent: .outsideEvent)
    }

    // MARK: - Gesture Handlers

    @objc private func handleContainerTap(_ gesture: UITapGestureRecognizer) {
        guard let containerView = gesture.view else { return }
        let location = gesture.location(in: containerView)
        if let toast = currentToast, !toast.frame.contains(location) {
            dismissToast(toast, dismissEvent: .tappedBackground)
            containerView.removeGestureRecognizer(gesture)
        }
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
                dismissToast(toast, dismissEvent: .swipedDown)
            } else {
                UIView.animate(withDuration: 0.2) {
                    toast.transform = .identity
                }
            }
        default: break
        }
    }

    // MARK: - Dismiss

    private func dismissToast(_ toast: UIView, dismissEvent: DismissEvent) {
        dismissWorkItem?.cancel()
        dismissWorkItem = nil

        let translationY = toast.frame.height + 50

        UIView.animate(withDuration: 0.25,
                       delay: 0,
                       options: [.curveEaseIn],
                       animations: {
            toast.transform = CGAffineTransform(translationX: 0, y: translationY)
            toast.alpha = 0
        }, completion: { _ in
            toast.removeFromSuperview()
            if self.currentToast === toast {
                self.currentToast = nil
            }

            if let backgroundTapGestureRecognizer = self.backgroundTapGestureRecognizer {
                backgroundTapGestureRecognizer.view?.removeGestureRecognizer(backgroundTapGestureRecognizer)
                self.backgroundTapGestureRecognizer = nil
            }

            self.dismissAction?(dismissEvent)
            self.dismissAction = nil
        })
    }
}

// MARK: - Toolbar Detection

extension UIViewController {
    func visibleToolbarHeightAboveSafeArea() -> CGFloat {
        if let tab = self as? UITabBarController ?? (self as? UINavigationController)?.viewControllers.first as? UITabBarController {
            let bar = tab.tabBar
            if !bar.isHidden, bar.alpha > 0 {
                let height = bar.frame.height - view.safeAreaInsets.bottom
                if height > 0 { return height }
            }
        }
        if let tab = (self as? UITabBarController) ?? children.first(where: { $0 is UITabBarController }) as? UITabBarController {
            let bar = tab.tabBar
            if !bar.isHidden, bar.alpha > 0 {
                let height = bar.frame.height - view.safeAreaInsets.bottom
                if height > 0 { return height }
            }
        }
        return 0
    }
}

// MARK: - Top View Controller Helpers

extension UIViewController {
    func topMostViewController() -> UIViewController {
        if let presented = self.presentedViewController {
            return presented.topMostViewController()
        }
        if let nav = self as? UINavigationController, let top = nav.topViewController {
            return top.topMostViewController()
        }
        if let tab = self as? UITabBarController, let selected = tab.selectedViewController {
            return selected.topMostViewController()
        }
        return self
    }
}

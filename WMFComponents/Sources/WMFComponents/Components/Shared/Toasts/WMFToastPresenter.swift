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
        currentToast?.backgroundColor = theme.paperBackground
        currentToast?.layer.shadowColor = theme.toastShadow.cgColor

        if let borderLayer = currentToast?.layer.sublayers?.first(where: { $0.borderWidth > 0 }) {
            borderLayer.borderColor = theme.border.withAlphaComponent(0.15).cgColor
        }
    }

    // MARK: - Public API

    /// Presents a toast using WMFToastConfig
    public func show(_ config: WMFToastConfig, dismissPreviousAlerts: Bool = false) {
        if dismissPreviousAlerts {
            dismissCurrentToast()
        }

        let toastView = WMFToastView(config: config, dismiss: { [weak self] in
            self?.dismissCurrentToast()
        })

        presentToastView(
            view: toastView,
            duration: config.duration,
            allowsBackgroundTapToDismiss: false,
            dismissAction: nil
        )
    }

    /// Presents a SwiftUI view as a toast at the bottom of the screen
    public func presentToastView<Content: View>(
        view: Content,
        duration: TimeInterval? = nil,
        allowsBackgroundTapToDismiss: Bool = false,
        dismissAction: (@Sendable (DismissEvent) -> Void)? = nil
    ) {
        guard let containerView = UIApplication.shared.currentTopViewController?.view else {
            debugPrint("No container view available")
            return
        }

        currentToast?.removeFromSuperview()
        dismissWorkItem?.cancel()
        self.dismissAction = dismissAction

        // SwiftUI hosting
        let toastContent = view
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)

        let hostingController = UIHostingController(rootView: toastContent)
        hostingController.view.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false

        // Outer shadow container (keeps shadow outside clipped corners)
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

        containerView.addSubview(shadowContainer)
        currentToast = shadowContainer

        // Position constraints (iPhone should always fill safe area width)
        let leading = shadowContainer.leadingAnchor.constraint(
            equalTo: containerView.safeAreaLayoutGuide.leadingAnchor,
            constant: 16
        )
        let trailing = shadowContainer.trailingAnchor.constraint(
            equalTo: containerView.safeAreaLayoutGuide.trailingAnchor,
            constant: -16
        )
        let bottom = shadowContainer.bottomAnchor.constraint(
            equalTo: containerView.safeAreaLayoutGuide.bottomAnchor,
            constant: -16
        )

        // Make these REQUIRED so iPhone doesn’t shrink
        leading.priority = .required
        trailing.priority = .required
        bottom.priority = .required

        NSLayoutConstraint.activate([leading, trailing, bottom])

        // iPad-only cap + centering (use idiom, not size class)
        if UIDevice.current.userInterfaceIdiom == .pad {
            let maxWidth: CGFloat = 400
            NSLayoutConstraint.activate([
                shadowContainer.widthAnchor.constraint(lessThanOrEqualToConstant: maxWidth),
                shadowContainer.centerXAnchor.constraint(equalTo: containerView.centerXAnchor)
            ])
        }

        // Layout before animation (so height is known)
        containerView.layoutIfNeeded()
        let translationY = shadowContainer.bounds.height + 50
        shadowContainer.transform = CGAffineTransform(translationX: 0, y: translationY)
        shadowContainer.alpha = 0

        UIView.animate(
            withDuration: 0.35,
            delay: 0,
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
        if let duration {
            let workItem = DispatchWorkItem { [weak self, weak shadowContainer] in
                guard let shadowContainer else { return }
                self?.dismissToast(shadowContainer, dismissEvent: .durationExpired)
            }
            dismissWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: workItem)
        }
    }

    public func dismissCurrentToast() {
        guard let toast = currentToast else { return }
        dismissToast(toast, dismissEvent: .outsideEvent)
    }

    public func dismissAll(completion: @escaping @MainActor () -> Void = {}) {
        guard let toast = currentToast else {
            completion()
            return
        }

        dismissWorkItem?.cancel()
        dismissWorkItem = nil

        toast.removeFromSuperview()
        if self.currentToast === toast {
            self.currentToast = nil
        }

        if let backgroundTapGestureRecognizer = self.backgroundTapGestureRecognizer {
            backgroundTapGestureRecognizer.view?.removeGestureRecognizer(backgroundTapGestureRecognizer)
            self.backgroundTapGestureRecognizer = nil
        }

        self.dismissAction = nil
        completion()
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
            // Allow swiping down
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

// MARK: - Top View Controller Helpers

extension UIApplication {
    var currentTopViewController: UIViewController? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController?
            .topMostViewController()
    }
}

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

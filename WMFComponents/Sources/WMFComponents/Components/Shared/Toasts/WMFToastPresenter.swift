import UIKit
import SwiftUI
import Combine

public final class WMFToastPresenter {
    
    // MARK: - Nested Types
    
    public enum DismissEvent {
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
    private var dismissAction: ((DismissEvent) -> Void)?
    
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
        currentToast?.layer.shadowColor =  theme.toastShadow.cgColor
    }

    // MARK: - Public API

    /// Presents a SwiftUI view as a toast at the bottom of the screen
    public func presentToastView<Content: View>(
        view: Content,
        duration: TimeInterval? = nil,
        allowsBackgroundTapToDismiss: Bool = false,
        dismissAction: ((DismissEvent) -> Void)? = nil
    ) {
        guard let containerView = UIApplication.shared.currentTopViewController?.view else {
            debugPrint("No container view available")
            return
        }

        // Remove any existing toast
        currentToast?.removeFromSuperview()
        dismissWorkItem?.cancel()
        
        self.dismissAction = dismissAction

        // SwiftUI hosting controller
        let toastContent = view
            .frame(maxWidth: .infinity, alignment: .leading)
        let hostingController = UIHostingController(rootView: toastContent)
        hostingController.view.backgroundColor = .clear
        hostingController.view.insetsLayoutMarginsFromSafeArea = false
        hostingController.view.layoutMargins = .zero

        // Container view with shadow & background
        let toastContainer = UIView()
        toastContainer.backgroundColor = theme.paperBackground
        toastContainer.layer.cornerRadius = 12
        toastContainer.layer.shadowColor =  theme.toastShadow.cgColor
        toastContainer.layer.shadowOffset = CGSize(width: 0, height: 1)
        toastContainer.layer.shadowRadius = 10
        toastContainer.layer.shadowOpacity = 0.5
        toastContainer.translatesAutoresizingMaskIntoConstraints = false

        toastContainer.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false

        // containerView = current top view controller
        // toastContainer = rounded shadow view
        // hostingController = toast content
        
        let verticalPadding: CGFloat = 16
        let horizontalPadding: CGFloat = 12
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: toastContainer.topAnchor, constant: verticalPadding),
            hostingController.view.leadingAnchor.constraint(equalTo: toastContainer.leadingAnchor, constant: horizontalPadding),
            hostingController.view.trailingAnchor.constraint(equalTo: toastContainer.trailingAnchor, constant: -horizontalPadding),
            hostingController.view.bottomAnchor.constraint(equalTo: toastContainer.bottomAnchor, constant: -verticalPadding)
        ])

        containerView.addSubview(toastContainer)
        currentToast = toastContainer
        
        // iPad handling
        let maxWidth: CGFloat = 400
        let toastWidth = toastContainer.widthAnchor.constraint(lessThanOrEqualToConstant: maxWidth)
        
        // Need to loosen these up so that iPad doesn't stretch across the device
        let toastLeading = toastContainer.leadingAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.leadingAnchor, constant: 16)
        let toastTrailing = toastContainer.trailingAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.trailingAnchor, constant: -16)
        toastLeading.priority = .defaultHigh
        toastTrailing.priority = .defaultHigh

        // Constrain toast to container view
        NSLayoutConstraint.activate([
            toastLeading,
            toastTrailing,
            toastWidth,
            toastContainer.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            toastContainer.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])

        // Initial state off-screen (bottom)
        toastContainer.transform = CGAffineTransform(translationX: 0, y: toastContainer.frame.height + 50)
        toastContainer.alpha = 0

        // Animate in
        UIView.animate(withDuration: 0.35,
                       delay: 0,
                       usingSpringWithDamping: 0.8,
                       initialSpringVelocity: 0.5,
                       options: [.curveEaseOut],
                       animations: {
            toastContainer.transform = .identity
            toastContainer.alpha = 1
        })

        // Tap outside to dismiss
        if allowsBackgroundTapToDismiss {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleContainerTap(_:)))
            tapGesture.cancelsTouchesInView = false
            containerView.addGestureRecognizer(tapGesture)
            self.backgroundTapGestureRecognizer = tapGesture
        }

        // Swipe down to dismiss
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleToastPan(_:)))
        toastContainer.addGestureRecognizer(panGesture)

        // Auto-dismiss
        if let duration {
            let workItem = DispatchWorkItem { [weak self, weak toastContainer] in
                guard let toastContainer = toastContainer else { return }
                self?.dismissToast(toastContainer, dismissEvent: .durationExpired)
            }
            dismissWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: workItem)
        }
    }
    
    public func dismissCurrentToast() {
        
        guard let toast = currentToast else { return }
        
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
            if translation.y > 50 || velocity.y > 500 {
                dismissToast(toast, dismissEvent: .swipedDown)
            } else {
                // Snap back
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

        UIView.animate(withDuration: 0.25,
                       delay: 0,
                       options: [.curveEaseIn],
                       animations: {
            toast.transform = CGAffineTransform(translationX: 0, y: toast.frame.height + 50)
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

import UIKit
import SwiftUI

public final class WMFToastPresenter {

    public static let shared = WMFToastPresenter()
    private init() {}

    private var currentToast: UIView?
    private var dismissWorkItem: DispatchWorkItem?

    // MARK: - Public API

    /// Presents a SwiftUI view as a toast at the bottom of the screen
    public func presentToastView<Content: View>(
        view: Content,
        duration: TimeInterval = 2.0
    ) {
        guard let containerView = UIApplication.shared.currentTopViewController?.view else {
            debugPrint("No container view available")
            return
        }

        // Remove any existing toast
        currentToast?.removeFromSuperview()
        dismissWorkItem?.cancel()

        // SwiftUI hosting controller
        let hostingController = UIHostingController(rootView: view)
        hostingController.view.backgroundColor = .clear
        hostingController.view.layer.cornerRadius = 12
        hostingController.view.layer.masksToBounds = true

        // Container view with shadow & background
        let toastContainer = UIView()
        toastContainer.backgroundColor = UIColor.systemBackground
        toastContainer.layer.cornerRadius = 12
        toastContainer.layer.shadowColor = UIColor.black.cgColor
        toastContainer.layer.shadowOpacity = 0.2
        toastContainer.layer.shadowOffset = .zero
        toastContainer.layer.shadowRadius = 6
        toastContainer.translatesAutoresizingMaskIntoConstraints = false

        toastContainer.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false

        let padding: CGFloat = 12
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: toastContainer.topAnchor, constant: padding),
            hostingController.view.leadingAnchor.constraint(equalTo: toastContainer.leadingAnchor, constant: padding),
            hostingController.view.trailingAnchor.constraint(equalTo: toastContainer.trailingAnchor, constant: -padding),
            hostingController.view.bottomAnchor.constraint(equalTo: toastContainer.bottomAnchor, constant: -padding)
        ])

        containerView.addSubview(toastContainer)
        currentToast = toastContainer

        let maxWidth: CGFloat = 400
        NSLayoutConstraint.activate([
            toastContainer.leadingAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            toastContainer.trailingAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            toastContainer.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            toastContainer.widthAnchor.constraint(lessThanOrEqualToConstant: maxWidth)
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
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleContainerTap(_:)))
        tapGesture.cancelsTouchesInView = false
        containerView.addGestureRecognizer(tapGesture)

        // Swipe down to dismiss
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleToastPan(_:)))
        toastContainer.addGestureRecognizer(panGesture)

        // Auto-dismiss
        let workItem = DispatchWorkItem { [weak self, weak toastContainer] in
            guard let toastContainer = toastContainer else { return }
            self?.dismissToast(toastContainer)
            containerView.removeGestureRecognizer(tapGesture)
        }
        dismissWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: workItem)
    }

    // MARK: - Gesture Handlers

    @objc private func handleContainerTap(_ gesture: UITapGestureRecognizer) {
        guard let containerView = gesture.view else { return }
        let location = gesture.location(in: containerView)
        if let toast = currentToast, !toast.frame.contains(location) {
            dismissToast(toast)
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
                dismissToast(toast)
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

    private func dismissToast(_ toast: UIView) {
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

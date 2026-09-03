import UIKit
import Combine

/// Shows one toast at a time at the bottom of a window.
///
/// The presenter adds a `WMFToastCardView` to the window, positions it above the
/// tab bar or the keyboard, and removes it after a delay or a gesture.
@MainActor
public final class WMFToastPresenter {

    // MARK: - Nested Types

    /// The reason a toast closed.
    public enum DismissEvent: Sendable {
        case tappedBackground
        case durationExpired
        case swipedDown
        case outsideEvent
    }

    private enum Layout {
        static let horizontalMargin: CGFloat = 16
        static let bottomMargin: CGFloat = 24
        static let iPadMaxWidth: CGFloat = 400
        static let offScreenTranslation: CGFloat = 200
    }

    // MARK: - Properties

    public static let shared = WMFToastPresenter()

    private var cancellables = Set<AnyCancellable>()

    private var currentCard: WMFToastCardView?
    private var dismissWorkItem: DispatchWorkItem?
    private var dismissAction: ((DismissEvent) -> Void)?

    private var currentKeyboardHeight: CGFloat = 0

    // MARK: - Lifecycle

    private init() {
        WMFAppEnvironment.publisher
            .sink { [weak self] _ in self?.currentCard?.applyTheme() }
            .store(in: &cancellables)

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)), name: UIWindow.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIWindow.keyboardWillHideNotification, object: nil)
    }

    // MARK: - Public API

    /// True when a toast is in a window.
    public var isToastVisible: Bool {
        currentCard?.window != nil
    }

    /// Shows a toast.
    ///
    /// If a toast is already on screen, the presenter replaces its content in place
    /// and restarts the timer. Pass a window to show the toast in that window.
    /// Without a window, the presenter uses the key window.
    ///
    /// - Parameter dismissAction: The presenter calls this closure one time, after the toast leaves the screen.
    public func show(
        _ config: WMFToastConfig,
        in window: UIWindow? = nil,
        dismissAction: ((DismissEvent) -> Void)? = nil
    ) {
        if let currentCard, currentCard.window != nil {
            currentCard.configure(with: config)
            self.dismissAction = dismissAction
            scheduleDismiss(after: config.duration, for: currentCard)
            return
        }

        guard let window = window ?? keyWindow() else {
            debugPrint("WMFToastPresenter: no window is available")
            return
        }

        dismissWorkItem?.cancel()
        dismissWorkItem = nil
        self.dismissAction = dismissAction

        let card = WMFToastCardView(config: config)
        card.translatesAutoresizingMaskIntoConstraints = false
        card.dismiss = { [weak self, weak card] in
            guard let self, let card else { return }
            self.dismiss(card, event: .outsideEvent)
        }

        // Start off screen and invisible before the view joins the hierarchy.
        // This prevents a flash on the first frame.
        card.transform = CGAffineTransform(translationX: 0, y: Layout.offScreenTranslation)
        card.alpha = 0

        window.addSubview(card)
        currentCard = card

        activateConstraints(for: card, in: window)

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        card.addGestureRecognizer(panGesture)

        UIView.animate(
            withDuration: 0.35,
            delay: 0,
            usingSpringWithDamping: 0.85,
            initialSpringVelocity: 0.6,
            options: [.curveEaseOut],
            animations: {
                card.transform = .identity
                card.alpha = 1
            }
        )

        scheduleDismiss(after: config.duration, for: card)
    }

    /// Closes the current toast with an animation.
    ///
    /// - Parameter completion: The presenter calls this closure after the toast leaves the screen.
    ///   It calls the closure at once when no toast is on screen.
    public func dismissCurrentToast(completion: (() -> Void)? = nil) {
        guard let card = currentCard else {
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
        dismiss(card, event: .outsideEvent)
    }

    // MARK: - Layout

    private func keyWindow() -> UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }

    private func activateConstraints(for card: UIView, in window: UIWindow) {
        let safeArea = window.safeAreaLayoutGuide

        // Sit above the keyboard when it is up. Otherwise sit above the tab bar or toolbar.
        // When there is no bar, sit on the bottom of the safe area.
        let toolbarOffset = currentKeyboardHeight > 0
            ? currentKeyboardHeight
            : window.rootViewController?.visibleToolbarHeightAboveSafeArea() ?? 0
        let bottomConstant = toolbarOffset > 0 ? -(Layout.bottomMargin + toolbarOffset) : 0

        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: Layout.horizontalMargin),
            card.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -Layout.horizontalMargin),
            card.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: bottomConstant)
        ])

        if UIDevice.current.userInterfaceIdiom == .pad {
            NSLayoutConstraint.activate([
                card.widthAnchor.constraint(lessThanOrEqualToConstant: Layout.iPadMaxWidth),
                card.centerXAnchor.constraint(equalTo: window.centerXAnchor)
            ])
        }
    }

    // MARK: - Keyboard

    @objc private func keyboardWillChangeFrame(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let window = keyWindow() else { return }

        currentKeyboardHeight = max(0, window.bounds.height - keyboardFrame.minY)
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        currentKeyboardHeight = 0
    }

    // MARK: - Gestures

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let card = gesture.view as? WMFToastCardView else { return }
        let translation = gesture.translation(in: card.superview)

        switch gesture.state {
        case .changed:
            if translation.y > 0 {
                card.transform = CGAffineTransform(translationX: 0, y: translation.y)
            }
        case .ended, .cancelled:
            let velocity = gesture.velocity(in: card)
            let shouldDismiss = translation.y > 50 || velocity.y > 500

            if shouldDismiss {
                dismiss(card, event: .swipedDown)
            } else {
                UIView.animate(withDuration: 0.2) {
                    card.transform = .identity
                }
            }
        default:
            break
        }
    }

    // MARK: - Dismiss

    private func scheduleDismiss(after duration: TimeInterval?, for card: WMFToastCardView) {
        dismissWorkItem?.cancel()
        dismissWorkItem = nil

        guard let duration, duration > 0 else { return }

        let workItem = DispatchWorkItem { [weak self, weak card] in
            guard let self, let card else { return }
            self.dismiss(card, event: .durationExpired)
        }
        dismissWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: workItem)
    }

    private func dismiss(_ card: WMFToastCardView, event: DismissEvent) {
        guard currentCard === card else { return }

        dismissWorkItem?.cancel()
        dismissWorkItem = nil
        currentCard = nil

        let action = dismissAction
        dismissAction = nil

        let translationY = card.frame.height + 50

        UIView.animate(
            withDuration: 0.25,
            delay: 0,
            options: [.curveEaseIn],
            animations: {
                card.transform = CGAffineTransform(translationX: 0, y: translationY)
                card.alpha = 0
            },
            completion: { _ in
                card.removeFromSuperview()
                action?(event)
            }
        )
    }
}

// MARK: - Toolbar Detection

private extension UIViewController {

    /// Returns the height of the visible tab bar above the bottom safe area, or 0.
    func visibleToolbarHeightAboveSafeArea() -> CGFloat {
        // A full screen modal covers the tab bar.
        if let presented = presentedViewController,
           presented.modalPresentationStyle == .fullScreen || presented.modalPresentationStyle == .overFullScreen {
            return 0
        }

        let tabBarController = (self as? UITabBarController)
            ?? ((self as? UINavigationController)?.viewControllers.first as? UITabBarController)
            ?? (children.first { $0 is UITabBarController } as? UITabBarController)

        guard let bar = tabBarController?.tabBar, !bar.isHidden, bar.alpha > 0 else {
            return 0
        }

        let height = bar.frame.height - view.safeAreaInsets.bottom
        return max(0, height)
    }
}

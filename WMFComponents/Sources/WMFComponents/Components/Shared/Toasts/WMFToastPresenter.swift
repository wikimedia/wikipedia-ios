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
        static let keyboardMargin: CGFloat = 16
        static let iPadMaxWidth: CGFloat = 400
        static let offScreenTranslation: CGFloat = 200
    }

    private enum Animation {
        static let showDuration: TimeInterval = 0.35
        static let dismissDuration: TimeInterval = 0.25
        static let snapBackDuration: TimeInterval = 0.2
        static let springDamping: CGFloat = 0.85
        static let springVelocity: CGFloat = 0.6
    }

    // MARK: - Properties

    public static let shared = WMFToastPresenter()

    private var cancellables = Set<AnyCancellable>()

    private var currentCard: WMFToastCardView?
    private var showAnimator: UIViewPropertyAnimator?
    private var dismissTask: Task<Void, Never>?
    private var dismissAction: ((DismissEvent) -> Void)?

    // MARK: - Lifecycle

    private init() {
        WMFAppEnvironment.publisher
            .sink { [weak self] _ in self?.currentCard?.applyTheme() }
            .store(in: &cancellables)
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
            announce(config)
            return
        }

        guard let window = window ?? keyWindow() else {
            debugPrint("WMFToastPresenter: no window is available")
            return
        }

        dismissTask?.cancel()
        dismissTask = nil
        self.dismissAction = dismissAction

        let card = WMFToastCardView(config: config)
        card.translatesAutoresizingMaskIntoConstraints = false
        card.dismiss = { [weak self, weak card] in
            guard let self, let card else { return }
            self.dismiss(card, event: .outsideEvent)
        }

        // Start off screen and invisible before the view joins the hierarchy.
        // This prevents a flash on the first frame.
        card.transform = reduceMotion ? .identity : CGAffineTransform(translationX: 0, y: Layout.offScreenTranslation)
        card.alpha = 0

        window.addSubview(card)
        currentCard = card

        activateConstraints(for: card, in: window)

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        card.addGestureRecognizer(panGesture)

        showAnimator?.stopAnimation(true)
        showAnimator = makeShowAnimator(for: card)
        showAnimator?.startAnimation()

        scheduleDismiss(after: config.duration, for: card)
        announce(config)
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

    // MARK: - Accessibility

    /// Reads the toast text to VoiceOver users. The card is not in the focus order, so
    /// VoiceOver does not tell the user about it on its own.
    private func announce(_ config: WMFToastConfig) {
        let text = [config.title, config.subtitle].compactMap { $0 }.joined(separator: ". ")
        UIAccessibility.post(notification: .announcement, argument: text)
    }

    // MARK: - Animation

    /// True when the user asked the system to reduce motion. The presenter then fades the card in place.
    private var reduceMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    private func makeShowAnimator(for card: UIView) -> UIViewPropertyAnimator {
        if reduceMotion {
            return UIViewPropertyAnimator(duration: Animation.dismissDuration, curve: .easeOut) {
                card.alpha = 1
            }
        }

        let spring = UISpringTimingParameters(
            dampingRatio: Animation.springDamping,
            initialVelocity: CGVector(dx: 0, dy: Animation.springVelocity)
        )
        let animator = UIViewPropertyAnimator(duration: Animation.showDuration, timingParameters: spring)
        animator.addAnimations {
            card.transform = .identity
            card.alpha = 1
        }
        return animator
    }

    /// Stops the show animation and puts the card at its resting position.
    /// Call this before a gesture takes control of the card.
    private func finishShowAnimation(for card: UIView) {
        guard let showAnimator, showAnimator.isRunning else { return }
        showAnimator.stopAnimation(true)
        self.showAnimator = nil
        card.transform = .identity
        card.alpha = 1
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

        // Sit above the tab bar with a margin. When there is no tab bar, keep the same
        // margin from the bottom of the safe area, so the card does not touch the edge.
        let toolbarOffset = window.rootViewController?.visibleToolbarHeightAboveSafeArea() ?? 0
        let bottomConstant = -(Layout.bottomMargin + toolbarOffset)
        let restingBottom = card.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: bottomConstant)
        restingBottom.priority = .defaultHigh

        // Stay above the keyboard. The keyboard layout guide follows the keyboard, so the
        // card moves with it. When the keyboard is hidden, the guide sits on the bottom edge
        // of the window and this constraint has no effect on the resting position.
        window.keyboardLayoutGuide.usesBottomSafeArea = false
        let aboveKeyboard = card.bottomAnchor.constraint(lessThanOrEqualTo: window.keyboardLayoutGuide.topAnchor, constant: -Layout.keyboardMargin)

        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: Layout.horizontalMargin),
            card.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -Layout.horizontalMargin),
            restingBottom,
            aboveKeyboard
        ])

        if UIDevice.current.userInterfaceIdiom == .pad {
            NSLayoutConstraint.activate([
                card.widthAnchor.constraint(lessThanOrEqualToConstant: Layout.iPadMaxWidth),
                card.centerXAnchor.constraint(equalTo: window.centerXAnchor)
            ])
        }
    }

    // MARK: - Gestures

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let card = gesture.view as? WMFToastCardView else { return }
        let translation = gesture.translation(in: card.superview)

        switch gesture.state {
        case .began:
            finishShowAnimation(for: card)
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
                let snapBack = UIViewPropertyAnimator(duration: Animation.snapBackDuration, curve: .easeOut) {
                    card.transform = .identity
                }
                snapBack.startAnimation()
            }
        default:
            break
        }
    }

    // MARK: - Dismiss

    private func scheduleDismiss(after duration: TimeInterval?, for card: WMFToastCardView) {
        dismissTask?.cancel()
        dismissTask = nil

        guard let duration, duration > 0 else { return }

        dismissTask = Task { [weak self, weak card] in
            try? await Task.sleep(for: .seconds(duration))
            guard !Task.isCancelled, let self, let card else { return }
            self.dismiss(card, event: .durationExpired)
        }
    }

    private func dismiss(_ card: WMFToastCardView, event: DismissEvent) {
        guard currentCard === card else { return }

        dismissTask?.cancel()
        dismissTask = nil
        currentCard = nil

        let action = dismissAction
        dismissAction = nil

        finishShowAnimation(for: card)

        let translationY = card.frame.height + 50
        let fadeOnly = reduceMotion

        let animator = UIViewPropertyAnimator(duration: Animation.dismissDuration, curve: .easeIn) {
            if !fadeOnly {
                card.transform = CGAffineTransform(translationX: 0, y: translationY)
            }
            card.alpha = 0
        }
        animator.addCompletion { _ in
            card.removeFromSuperview()
            action?(event)
        }
        animator.startAnimation()
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

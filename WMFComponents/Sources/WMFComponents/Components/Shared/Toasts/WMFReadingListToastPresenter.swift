import UIKit
import SwiftUI

@MainActor
final public class WMFReadingListToastPresenter {

    // MARK: - Properties

    private weak var presenter: UIViewController?

    private var currentToastContainer: UIView?
    private var currentHostingController: UIHostingController<WMFReadingListToastView>?
    private var currentModel: WMFReadingListToastModel?

    private var containerViewConstraints: (top: NSLayoutConstraint?, bottom: NSLayoutConstraint?)?
    private var dismissWorkItem: DispatchWorkItem?

    private var subview: UIView?
    private var additionalBottomSpacing: CGFloat = 0
    private var extendsUnderSafeArea: Bool = false

    public init(presenter: UIViewController? = nil, currentToastContainer: UIView? = nil, currentHostingController: UIHostingController<WMFReadingListToastView>? = nil, currentModel: WMFReadingListToastModel? = nil, containerViewConstraints: (top: NSLayoutConstraint?, bottom: NSLayoutConstraint?)? = nil, dismissWorkItem: DispatchWorkItem? = nil, subview: UIView? = nil) {
        self.presenter = presenter
        self.currentToastContainer = currentToastContainer
        self.currentHostingController = currentHostingController
        self.currentModel = currentModel
        self.containerViewConstraints = containerViewConstraints
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
        guard isToastHidden != hidden, let presenter = presenter else {
            completion?()
            return
        }

        if hidden {
            dismissWorkItem?.cancel()
            dismissWorkItem = nil
        }

        if !hidden, isToastHidden, presenter.presentedViewController != nil {
            completion?()
            return
        }

        if !hidden {
            guard let config else {
                completion?()
                return
            }
            addToast(to: presenter, config: config)
        }

        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut], animations: {
            if hidden {
                self.containerViewConstraints?.bottom?.isActive = false
                self.containerViewConstraints?.top?.isActive = true
            } else {
                self.containerViewConstraints?.top?.isActive = false
                self.containerViewConstraints?.bottom?.isActive = true
            }
            self.currentToastContainer?.superview?.layoutIfNeeded()
        }, completion: { _ in
            if hidden {
                self.removeToast()
                completion?()
            } else {
                self.scheduleDismiss(config: config)
                completion?()
            }
        })
    }

    private func addToast(to outsidePresenter: UIViewController, config: WMFReadingListToastConfig) {
        guard isToastHidden else { return }
        
        // Note: using top window as a presenter fixes freezing during pan and matches WMFToastPresenter
        guard let presenter = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) else {
            debugPrint("No key window available")
            return
        }

        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .clear

        let bottomAnchor: NSLayoutYAxisAnchor = extendsUnderSafeArea
            ? presenter.bottomAnchor
            : presenter.safeAreaLayoutGuide.bottomAnchor

        if let subview = subview {
            presenter.insertSubview(containerView, belowSubview: subview)
        } else {
            presenter.addSubview(containerView)
        }

        let bottomConstraint = containerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -(additionalBottomSpacing + 24))
        let topConstraint = containerView.topAnchor.constraint(equalTo: bottomAnchor)

        NSLayoutConstraint.activate([
            topConstraint,
            containerView.leadingAnchor.constraint(equalTo: presenter.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: presenter.trailingAnchor)
        ])

        containerViewConstraints = (top: topConstraint, bottom: bottomConstraint)

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

        let shadowContainer = UIView()
        shadowContainer.translatesAutoresizingMaskIntoConstraints = false
        shadowContainer.backgroundColor = .clear
        if #unavailable(iOS 26.0) {
            // Glass effect handles its own depth on iOS 26+; add shadow on earlier versions
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

        presenter.layoutIfNeeded()
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

        currentHostingController?.willMove(toParent: nil)
        currentHostingController?.view.removeFromSuperview()
        currentHostingController?.removeFromParent()

        currentToastContainer?.removeFromSuperview()

        currentHostingController = nil
        currentToastContainer = nil
        containerViewConstraints = nil
        currentModel = nil
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

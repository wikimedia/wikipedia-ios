import UIKit
import SwiftUI
import Combine

/// Unlike toasts which present globally, hints are anchored to specific view controllers
@MainActor
final public class WMFReadingListToastPresenter {

    // MARK: - Properties

    private weak var presenter: UIViewController?

    private var currentToastContainer: UIView?
    private var currentHostingController: UIHostingController<WMFReadingListToastView>?
    private var currentModel: WMFReadingListToastModel?

    private var containerViewConstraints: (top: NSLayoutConstraint?, bottom: NSLayoutConstraint?)?
    private var dismissWorkItem: DispatchWorkItem?
    private var cancellables = Set<AnyCancellable>()

    private var subview: UIView?
    private var additionalBottomSpacing: CGFloat = 0
    private var extendsUnderSafeArea: Bool = false

    public init(presenter: UIViewController? = nil, currentHintContainer: UIView? = nil, currentHostingController: UIHostingController<WMFReadingListToastView>? = nil, currentModel: WMFReadingListToastModel? = nil, containerViewConstraints: (top: NSLayoutConstraint?, bottom: NSLayoutConstraint?)? = nil, dismissWorkItem: DispatchWorkItem? = nil, cancellables: Set<AnyCancellable> = Set<AnyCancellable>(), subview: UIView? = nil) {
        self.presenter = presenter
        self.currentToastContainer = currentHintContainer
        self.currentHostingController = currentHostingController
        self.currentModel = currentModel
        self.containerViewConstraints = containerViewConstraints
        self.dismissWorkItem = dismissWorkItem
        self.cancellables = cancellables
        self.subview = subview
    }

    public var theme: WMFTheme {
        WMFAppEnvironment.current.theme
    }

    // MARK: - Public API

    public var isToastHidden: Bool {
        currentToastContainer?.superview == nil
    }

    /// Show a hint anchored to a specific view controller
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

        // If a hint is already visible, replace it in-place
        if !isToastHidden {
            updateCurrentHint(with: config)
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

    public func dismissToastDueToUserInteraction() {
        guard !isToastHidden else { return }
        dismissToast()
    }

    public func updateCurrentHint(with config: WMFReadingListToastConfig) {
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

    private func addToast(to presenter: UIViewController, config: WMFReadingListToastConfig) {
        guard isToastHidden else { return }

        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .clear

        let bottomAnchor: NSLayoutYAxisAnchor = extendsUnderSafeArea
            ? presenter.view.bottomAnchor
            : presenter.view.safeAreaLayoutGuide.bottomAnchor

        if let subview = subview {
            presenter.view.insertSubview(containerView, belowSubview: subview)
        } else {
            presenter.view.addSubview(containerView)
        }

        let bottomConstraint = containerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -additionalBottomSpacing)
        let topConstraint = containerView.topAnchor.constraint(equalTo: bottomAnchor)

        NSLayoutConstraint.activate([
            topConstraint,
            containerView.leadingAnchor.constraint(equalTo: presenter.view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: presenter.view.trailingAnchor)
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

        let cornerRadius: CGFloat = 24

        let shadowContainer = UIView()
        shadowContainer.translatesAutoresizingMaskIntoConstraints = false
        shadowContainer.backgroundColor = .clear
        shadowContainer.layer.shadowColor = theme.toastShadow.cgColor
        shadowContainer.layer.shadowOffset = CGSize(width: 0, height: 8)
        shadowContainer.layer.shadowRadius = 16
        shadowContainer.layer.shadowOpacity = 1

        let clippedContainer = UIView()
        clippedContainer.translatesAutoresizingMaskIntoConstraints = false
        clippedContainer.backgroundColor = .clear
        clippedContainer.layer.cornerRadius = cornerRadius
        clippedContainer.clipsToBounds = true

        shadowContainer.addSubview(clippedContainer)
        clippedContainer.addSubview(hostingController.view)

        NSLayoutConstraint.activate([
            clippedContainer.topAnchor.constraint(equalTo: shadowContainer.topAnchor),
            clippedContainer.leadingAnchor.constraint(equalTo: shadowContainer.leadingAnchor),
            clippedContainer.trailingAnchor.constraint(equalTo: shadowContainer.trailingAnchor),
            clippedContainer.bottomAnchor.constraint(equalTo: shadowContainer.bottomAnchor),

            hostingController.view.topAnchor.constraint(equalTo: clippedContainer.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: clippedContainer.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: clippedContainer.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: clippedContainer.bottomAnchor)
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

        presenter.addChild(hostingController)
        hostingController.didMove(toParent: presenter)

        containerView.setContentHuggingPriority(.required, for: .vertical)
        containerView.setContentCompressionResistancePriority(.required, for: .vertical)

        currentToastContainer = containerView
        currentHostingController = hostingController

        presenter.view.layoutIfNeeded()
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

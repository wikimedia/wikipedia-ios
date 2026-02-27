import UIKit
import SwiftUI
import WMFComponents
import Combine

/// WMFHintPresenter manages hint display (bottom-anchored toasts with state transitions)
/// Unlike toasts which present globally, hints are anchored to specific view controllers
@MainActor
final class WMFHintPresenter {

    // MARK: - Properties

    private weak var presenter: UIViewController?

    private var currentHintContainer: UIView?
    private var currentHostingController: UIHostingController<WMFHintView>?
    private var currentModel: WMFHintModel?

    private var containerViewConstraints: (top: NSLayoutConstraint?, bottom: NSLayoutConstraint?)?
    private var dismissWorkItem: DispatchWorkItem?
    private var cancellables = Set<AnyCancellable>()

    private var subview: UIView?
    private var additionalBottomSpacing: CGFloat = 0
    private var extendsUnderSafeArea: Bool = false

    var theme: WMFTheme {
        WMFAppEnvironment.current.theme
    }

    // MARK: - Public API

    var isHintHidden: Bool {
        currentHintContainer?.superview == nil
    }

    /// Show a hint anchored to a specific view controller
    func show(
        config: WMFHintConfig,
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

        // If a hint is already visible, replace it in-place (no hide/show).
        if !isHintHidden {
            updateCurrentHint(with: config)
            return
        }

        setHintHidden(false, config: config)
    }

    func dismissHint() {
        guard !isHintHidden else { return }
        setHintHidden(true, config: nil)
    }

    func resetHint() {
        dismissWorkItem?.cancel()
        dismissWorkItem = nil
    }

    func dismissHintDueToUserInteraction() {
        guard !isHintHidden else { return }
        dismissHint()
    }

    func updateCurrentHint(with config: WMFHintConfig) {
        currentModel?.config = config
        scheduleDismiss(config: config)
    }

    // MARK: - Private Methods

    private func setHintHidden(_ hidden: Bool, config: WMFHintConfig?, completion: (() -> Void)? = nil) {
        guard isHintHidden != hidden, let presenter = presenter else {
            completion?()
            return
        }

        if hidden {
            dismissWorkItem?.cancel()
            dismissWorkItem = nil
        }

        if !hidden, presenter.presentedViewController != nil {
            completion?()
            return
        }

        if !hidden {
            guard let config else {
                completion?()
                return
            }
            addHint(to: presenter, config: config)
        }

        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut], animations: {
            if hidden {
                self.containerViewConstraints?.bottom?.isActive = false
                self.containerViewConstraints?.top?.isActive = true
            } else {
                self.containerViewConstraints?.top?.isActive = false
                self.containerViewConstraints?.bottom?.isActive = true
            }
            self.currentHintContainer?.superview?.layoutIfNeeded()
        }, completion: { _ in
            if hidden {
                self.removeHint()
                completion?()
            } else {
                self.scheduleDismiss(config: config)
                completion?()
            }
        })
    }

    private func addHint(to presenter: UIViewController, config: WMFHintConfig) {
        guard isHintHidden else { return }

        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false

        let bottomAnchor: NSLayoutYAxisAnchor = extendsUnderSafeArea ? presenter.view.bottomAnchor : presenter.view.safeAreaLayoutGuide.bottomAnchor

        if let subview = subview {
            presenter.view.insertSubview(containerView, belowSubview: subview)
        } else {
            presenter.view.addSubview(containerView)
        }

        let bottomConstraint = containerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -additionalBottomSpacing)
        let topConstraint = containerView.topAnchor.constraint(equalTo: bottomAnchor)

        let leadingConstraint = containerView.leadingAnchor.constraint(equalTo: presenter.view.leadingAnchor)
        let trailingConstraint = containerView.trailingAnchor.constraint(equalTo: presenter.view.trailingAnchor)

        NSLayoutConstraint.activate([topConstraint, leadingConstraint, trailingConstraint])

        containerViewConstraints = (top: topConstraint, bottom: bottomConstraint)

        let model = WMFHintModel(config: config)
        currentModel = model

        let hintView = WMFHintView(model: model, dismiss: { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                self.setHintHidden(true, config: nil)
            }
        })

        let hostingController = UIHostingController(rootView: hintView)
        hostingController.view.backgroundColor = .clear
        hostingController.view.insetsLayoutMarginsFromSafeArea = false
        hostingController.view.layoutMargins = .zero
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false

        let toastContainer = UIView()
        toastContainer.backgroundColor = theme.paperBackground
        toastContainer.layer.cornerRadius = 24
        toastContainer.layer.shadowColor = theme.toastShadow.cgColor
        toastContainer.layer.shadowOffset = CGSize(width: 0, height: 8)
        toastContainer.layer.shadowRadius = 16
        toastContainer.layer.shadowOpacity = 1
        toastContainer.translatesAutoresizingMaskIntoConstraints = false

        let borderLayer = CALayer()
        borderLayer.cornerRadius = 24
        toastContainer.layer.addSublayer(borderLayer)

        toastContainer.addSubview(hostingController.view)

        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: toastContainer.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: toastContainer.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: toastContainer.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: toastContainer.bottomAnchor)
        ])

        containerView.addSubview(toastContainer)

        // iPad handling - max width and centering
        let maxWidth: CGFloat = 400
        let toastWidth = toastContainer.widthAnchor.constraint(lessThanOrEqualToConstant: maxWidth)

        let toastLeading = toastContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16)
        let toastTrailing = toastContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16)
        toastLeading.priority = .defaultHigh
        toastTrailing.priority = .defaultHigh

        NSLayoutConstraint.activate([
            toastLeading,
            toastTrailing,
            toastWidth,
            toastContainer.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            toastContainer.topAnchor.constraint(equalTo: containerView.topAnchor),
            toastContainer.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        presenter.addChild(hostingController)
        hostingController.didMove(toParent: presenter)

        containerView.setContentHuggingPriority(.required, for: .vertical)
        containerView.setContentCompressionResistancePriority(.required, for: .vertical)

        currentHintContainer = containerView
        currentHostingController = hostingController

        containerView.superview?.layoutIfNeeded()

        // Update border layer frame after layout
        // TODO: Fix border
        DispatchQueue.main.async {
            borderLayer.frame = toastContainer.bounds
        }
    }

    private func removeHint() {
        dismissWorkItem?.cancel()
        dismissWorkItem = nil

        currentHostingController?.willMove(toParent: nil)
        currentHostingController?.view.removeFromSuperview()
        currentHostingController?.removeFromParent()

        currentHintContainer?.removeFromSuperview()

        currentHostingController = nil
        currentHintContainer = nil
        containerViewConstraints = nil
        currentModel = nil
    }

    private func scheduleDismiss(config: WMFHintConfig?) {
        guard let config, let duration = config.duration else { return }

        dismissWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                self.setHintHidden(true, config: nil)
            }
        }
        dismissWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: workItem)
    }
}

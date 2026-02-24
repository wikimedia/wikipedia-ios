import UIKit
import SwiftUI
import WMFComponents
import Combine

/// WMFHintPresenter manages hint display (bottom-anchored toasts with state transitions)
/// Unlike toasts which present globally, hints are anchored to specific view controllers
@MainActor
class WMFHintPresenter {

    // MARK: - Properties

    private weak var presenter: UIViewController?
    private var currentHintContainer: UIView?
    private var currentHostingController: UIHostingController<WMFHintView>?
    private var currentViewModel: WMFHintViewModel?
    private var containerViewConstraints: (top: NSLayoutConstraint?, bottom: NSLayoutConstraint?)?
    private var dismissWorkItem: DispatchWorkItem?
    private var cancellables = Set<AnyCancellable>()

    private var subview: UIView?
    private var additionalBottomSpacing: CGFloat = 0
    private var extendsUnderSafeArea: Bool = false

    var theme: WMFTheme {
        return WMFAppEnvironment.current.theme
    }

    // MARK: - Lifecycle

    init() {
        subscribeToAppEnvironmentChanges()
    }

    // MARK: - AppEnvironment Subscription

    private func subscribeToAppEnvironmentChanges() {
        WMFAppEnvironment.publisher
            .sink(receiveValue: { [weak self] _ in self?.appEnvironmentDidChange() })
            .store(in: &cancellables)
    }

    private func appEnvironmentDidChange() {
        currentHintContainer?.backgroundColor = theme.paperBackground
        currentHintContainer?.layer.shadowColor = theme.toastShadow.cgColor
    }

    // MARK: - Public API

    var isHintHidden: Bool {
        return currentHintContainer?.superview == nil
    }

    /// Show a hint anchored to a specific view controller
    func show(
        config: WMFHintConfig,
        in presenter: UIViewController,
        subview: UIView? = nil,
        additionalBottomSpacing: CGFloat = 0,
        extendsUnderSafeArea: Bool = false
    ) {
        // If a hint is already visible, dismiss it first
        if !isHintHidden {
            setHintHidden(true, config: nil) { [weak self] in
                self?.showNewHint(config: config, in: presenter, subview: subview, additionalBottomSpacing: additionalBottomSpacing, extendsUnderSafeArea: extendsUnderSafeArea)
            }
        } else {
            showNewHint(config: config, in: presenter, subview: subview, additionalBottomSpacing: additionalBottomSpacing, extendsUnderSafeArea: extendsUnderSafeArea)
        }
    }

    private func showNewHint(
        config: WMFHintConfig,
        in presenter: UIViewController,
        subview: UIView?,
        additionalBottomSpacing: CGFloat,
        extendsUnderSafeArea: Bool
    ) {
        self.presenter = presenter
        self.subview = subview
        self.additionalBottomSpacing = additionalBottomSpacing
        self.extendsUnderSafeArea = extendsUnderSafeArea

        setHintHidden(false, config: config)
    }

    /// Dismiss the current hint
    func dismissHint() {
        guard !isHintHidden else { return }
        setHintHidden(true, config: nil)
    }

    /// Reset hint state (called when showing a new hint while one is visible)
    func resetHint() {
        dismissWorkItem?.cancel()
        dismissWorkItem = nil
    }

    /// Dismiss hint due to user interaction (swipe/scroll)
    func dismissHintDueToUserInteraction() {
        guard !isHintHidden else { return }
        dismissHint()
    }

    // MARK: - Private Methods

    private func setHintHidden(_ hidden: Bool, config: WMFHintConfig?, completion: (() -> Void)? = nil) {
        guard isHintHidden != hidden, let presenter = presenter else {
            completion?()
            return
        }

        // If hiding, stop any pending auto-dismiss.
        if hidden {
            dismissWorkItem?.cancel()
            dismissWorkItem = nil
        }

        // Only block *showing* when something is presented.
        if !hidden, presenter.presentedViewController != nil {
            dismissWorkItem?.cancel()
            dismissWorkItem = nil
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

    // TODO: check layout issues
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

        let viewModel = WMFHintViewModel(config: config)
        currentViewModel = viewModel

        let hintView = WMFHintView(viewModel: viewModel, dismiss: { [weak self] in
            self?.setHintHidden(true, config: nil)
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
        toastContainer.layer.shadowOpacity = 0.15
        toastContainer.translatesAutoresizingMaskIntoConstraints = false

        let borderLayer = CALayer()
        borderLayer.frame = CGRect(x: 0, y: 0, width: 1000, height: 1000)
        borderLayer.cornerRadius = 24
        borderLayer.borderWidth = 0.5
        borderLayer.borderColor = theme.border.withAlphaComponent(0.15).cgColor
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
        // TODO: Try to use a mor modern API here
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
        currentViewModel = nil
        currentHintContainer = nil
        containerViewConstraints = nil
    }

    private func scheduleDismiss(config: WMFHintConfig?) {
        guard let config = config, let duration = config.duration else { return }

        dismissWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.setHintHidden(true, config: nil)
        }
        dismissWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: workItem)
    }
    /// Update the current hint with new config (e.g., to add an image after loading)
    func updateCurrentHint(with config: WMFHintConfig) {
        print("🔍 updateCurrentHint called")
        print("🔍 currentViewModel exists: \(currentViewModel != nil)")

        guard let currentViewModel = currentViewModel else {
            print("🔍 ERROR: currentViewModel is nil!")
            return
        }

        print("🔍 Updating viewModel config - title: \(config.title)")
        print("🔍 Has icon: \(config.icon != nil)")
        currentViewModel.update(config: config)
        print("🔍 Update complete")

        // Ensure hint container is visible and brought to front
        bringHintToFront()
    }

    /// Bring hint container to front of its superview
    private func bringHintToFront() {
        guard let container = currentHintContainer else { return }
        print("🔍 Bringing hint to front")
        container.superview?.bringSubviewToFront(container)
    }
}

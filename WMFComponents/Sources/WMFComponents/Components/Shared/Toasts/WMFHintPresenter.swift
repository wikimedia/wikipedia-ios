import UIKit
import SwiftUI
import Combine

/// Unlike toasts which present globally, hints are anchored to specific view controllers
@MainActor
final public class WMFHintPresenter {

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

    public init(presenter: UIViewController? = nil, currentHintContainer: UIView? = nil, currentHostingController: UIHostingController<WMFHintView>? = nil, currentModel: WMFHintModel? = nil, containerViewConstraints: (top: NSLayoutConstraint?, bottom: NSLayoutConstraint?)? = nil, dismissWorkItem: DispatchWorkItem? = nil, cancellables: Set<AnyCancellable> = Set<AnyCancellable>(), subview: UIView? = nil) {
        self.presenter = presenter
        self.currentHintContainer = currentHintContainer
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

    public var isHintHidden: Bool {
        currentHintContainer?.superview == nil
    }

    /// Show a hint anchored to a specific view controller
    public func show(
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

        // If a hint is already visible, replace it in-place
        if !isHintHidden {
            updateCurrentHint(with: config)
            return
        }

        setHintHidden(false, config: config)
    }

    public func dismissHint() {
        guard !isHintHidden else { return }
        setHintHidden(true, config: nil)
    }

    public func resetHint() {
        dismissWorkItem?.cancel()
        dismissWorkItem = nil
    }

    public func dismissHintDueToUserInteraction() {
        guard !isHintHidden else { return }
        dismissHint()
    }

    public func updateCurrentHint(with config: WMFHintConfig) {
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
        containerView.backgroundColor = .clear

        let bottomAnchor: NSLayoutYAxisAnchor = extendsUnderSafeArea
            ? presenter.view.bottomAnchor
            : presenter.view.safeAreaLayoutGuide.bottomAnchor

        if let subview = subview {
            presenter.view.insertSubview(containerView, belowSubview: subview)
        } else {
            presenter.view.addSubview(containerView)
        }

        // These two constraints are toggled in setHintHidden(_:...)
        let bottomConstraint = containerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -additionalBottomSpacing)
        let topConstraint = containerView.topAnchor.constraint(equalTo: bottomAnchor)

        NSLayoutConstraint.activate([
            topConstraint,
            containerView.leadingAnchor.constraint(equalTo: presenter.view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: presenter.view.trailingAnchor)
        ])

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

        if #available(iOS 16.0, *) {
            hostingController.sizingOptions = [.intrinsicContentSize]
        }

        hostingController.view.setContentHuggingPriority(.required, for: .vertical)
        hostingController.view.setContentCompressionResistancePriority(.required, for: .vertical)

        let shadowContainer = UIView()
        shadowContainer.translatesAutoresizingMaskIntoConstraints = false
        shadowContainer.backgroundColor = .clear
        shadowContainer.layer.shadowColor = theme.toastShadow.cgColor
        shadowContainer.layer.shadowOffset = CGSize(width: 0, height: 8)
        shadowContainer.layer.shadowRadius = 16
        shadowContainer.layer.shadowOpacity = 0.15

        let clippedContainer = UIView()
        clippedContainer.translatesAutoresizingMaskIntoConstraints = false
        clippedContainer.backgroundColor = .clear
        clippedContainer.layer.cornerRadius = 20
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

        currentHintContainer = containerView
        currentHostingController = hostingController

        presenter.view.layoutIfNeeded()
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

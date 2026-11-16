import UIKit
import SwiftUI

fileprivate final class WMFAnalyticsInspectorPillHostingController: WMFComponentHostingController<WMFAnalyticsInspectorPillView> {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        sizingOptions = .intrinsicContentSize
    }
}

/// Transparent root view controller for the Analytics Inspector window. It places the pill under the
/// top safe area and lets the user drag it away from what it covers. Only the pill takes touches;
/// the window that hosts this controller returns the rest to the app.
public final class WMFAnalyticsInspectorPillViewController: UIViewController {

    private let viewModel: WMFAnalyticsInspectorViewModel
    private let hostingController: WMFAnalyticsInspectorPillHostingController

    private var trailingConstraint: NSLayoutConstraint?
    private var topConstraint: NSLayoutConstraint?

    public init(viewModel: WMFAnalyticsInspectorViewModel) {
        self.viewModel = viewModel
        self.hostingController = WMFAnalyticsInspectorPillHostingController(rootView: WMFAnalyticsInspectorPillView(viewModel: viewModel))
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// The view that takes touches. The hosting window uses it to decide what passes through.
    public var pillView: UIView {
        hostingController.view
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)

        let pillView = hostingController.view!
        pillView.translatesAutoresizingMaskIntoConstraints = false
        let trailingConstraint = pillView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -WMFSpacing.small)
        let topConstraint = pillView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: WMFSpacing.small)
        NSLayoutConstraint.activate([trailingConstraint, topConstraint])
        self.trailingConstraint = trailingConstraint
        self.topConstraint = topConstraint

        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(didPan(_:)))
        pillView.addGestureRecognizer(panGestureRecognizer)
    }

    @objc private func didPan(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard let trailingConstraint, let topConstraint else {
            return
        }
        let translation = gestureRecognizer.translation(in: view)
        gestureRecognizer.setTranslation(.zero, in: view)

        let safeArea = view.safeAreaLayoutGuide.layoutFrame
        let pillSize = hostingController.view.bounds.size
        let minimumTrailing = -(safeArea.width - pillSize.width - WMFSpacing.small)
        let maximumTop = safeArea.height - pillSize.height - WMFSpacing.small

        trailingConstraint.constant = min(-WMFSpacing.small, max(minimumTrailing, trailingConstraint.constant + translation.x))
        topConstraint.constant = min(maximumTop, max(WMFSpacing.small, topConstraint.constant + translation.y))
    }
}

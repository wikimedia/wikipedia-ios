import UIKit

fileprivate final class WMFAnalyticsInspectorListHostingController: WMFComponentHostingController<WMFAnalyticsInspectorListView> {
}

/// The modal list of recent analytics events, opened from the Analytics Inspector pill.
public final class WMFAnalyticsInspectorViewController: WMFCanvasViewController, WMFNavigationBarConfiguring {

    private let viewModel: WMFAnalyticsInspectorViewModel
    private let hostingViewController: WMFAnalyticsInspectorListHostingController

    /// Set by the app. Called once after the screen is dismissed.
    public var didDismiss: (@MainActor () -> Void)?

    public init(viewModel: WMFAnalyticsInspectorViewModel) {
        self.viewModel = viewModel
        self.hostingViewController = WMFAnalyticsInspectorListHostingController(rootView: WMFAnalyticsInspectorListView(viewModel: viewModel))
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        addComponent(hostingViewController, pinToEdges: true)
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBar()
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        let isDismissing = navigationController?.isBeingDismissed ?? isBeingDismissed
        if isDismissing {
            didDismiss?()
        }
    }

    private func configureNavigationBar() {
        let titleConfig = WMFNavigationBarTitleConfig(title: viewModel.localizedStrings.title, customView: nil, alignment: .centerCompact)
        let closeConfig = WMFLargeCloseButtonConfig(imageType: .plainX, target: self, action: #selector(tappedClose), alignment: .leading)
        configureNavigationBar(titleConfig: titleConfig, closeButtonConfig: closeConfig, profileButtonConfig: nil, tabsButtonConfig: nil, searchBarConfig: nil, hideNavigationBarOnScroll: false)
    }

    @objc private func tappedClose() {
        dismiss(animated: true)
    }
}

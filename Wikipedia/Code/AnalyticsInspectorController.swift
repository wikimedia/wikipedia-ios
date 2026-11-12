import UIKit
import WMFComponents
import WMFData

/// Window for the Analytics Inspector pill. Touches outside the pill, and outside a sheet the
/// window presents, go to the app window below.
final class AnalyticsInspectorWindow: UIWindow {

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let view = super.hitTest(point, with: event) else {
            return nil
        }
        if view === self || view === rootViewController?.view {
            return nil
        }
        return view
    }
}

/// Shows the Analytics Inspector pill over the app while its developer setting is on, and opens
/// the event list when the pill is tapped.
@MainActor
final class AnalyticsInspectorController {

    /// The inspector is an internal tool. Only Xcode, Staging and Experimental builds have it.
    /// The production app does not, in the App Store or in its TestFlight beta.
    static var isAvailableInThisBuild: Bool {
#if DEBUG || WMF_ALPHA || WMF_EXPERIMENTAL
        return true
#else
        return false
#endif
    }

    private let windowScene: UIWindowScene
    private var window: AnalyticsInspectorWindow?
    private var viewModel: WMFAnalyticsInspectorViewModel?
    private var observer: NSObjectProtocol?

    init(windowScene: UIWindowScene) {
        self.windowScene = windowScene
    }

    deinit {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func start() {
        observer = NotificationCenter.default.addObserver(forName: WMFNSNotification.analyticsInspectorVisibilityDidChange, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                self?.updateVisibility()
            }
        }
        updateVisibility()
    }

    private func updateVisibility() {
        if WMFDeveloperSettingsDataController.shared.showAnalyticsInspector {
            showWindow()
        } else {
            hideWindow()
        }
    }

    private func showWindow() {
        guard window == nil else {
            return
        }

        let viewModel = WMFAnalyticsInspectorViewModel()
        viewModel.didTapPill = { [weak self] in
            self?.presentList()
        }
        viewModel.start()

        let window = AnalyticsInspectorWindow(windowScene: windowScene)
        window.windowLevel = .alert + 1
        window.backgroundColor = .clear
        window.rootViewController = WMFAnalyticsInspectorPillViewController(viewModel: viewModel)
        window.isHidden = false

        self.window = window
        self.viewModel = viewModel
    }

    private func hideWindow() {
        viewModel?.stop()
        window?.rootViewController?.dismiss(animated: false)
        window?.isHidden = true
        window = nil
        viewModel = nil
    }

    /// The list is presented inside the inspector window, so it shows above whatever the app
    /// presents. The window becomes key while the list is up so its search field takes the keyboard.
    private func presentList() {
        guard let window, let viewModel, let rootViewController = window.rootViewController, rootViewController.presentedViewController == nil else {
            return
        }

        let previousKeyWindow = windowScene.keyWindow
        let listViewController = WMFAnalyticsInspectorViewController(viewModel: viewModel)
        listViewController.didDismiss = {
            previousKeyWindow?.makeKey()
        }
        let navigationController = WMFComponentNavigationController(rootViewController: listViewController, modalPresentationStyle: .pageSheet)
        window.makeKey()
        rootViewController.present(navigationController, animated: true)
    }
}

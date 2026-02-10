import UIKit
import SwiftUI
import Combine

fileprivate final class WMFSettingsHostingController: WMFComponentHostingController<WMFSettingsView> {}

final public class WMFSettingsViewController: WMFCanvasViewController, WMFNavigationBarConfiguring {

    private let viewModel: WMFSettingsViewModel
    private let hostingViewController: WMFSettingsHostingController
    let coordinatorDelegate: SettingsCoordinatorDelegate?

    public init(viewModel: WMFSettingsViewModel, coordinatorDelegate: SettingsCoordinatorDelegate?) {
        self.viewModel = viewModel
        self.coordinatorDelegate = coordinatorDelegate
        let rootView = WMFSettingsView(viewModel: viewModel)
        self.hostingViewController = WMFSettingsHostingController(rootView: rootView)
        super.init()
        viewModel.coordinatorDelegate = coordinatorDelegate
    }

    @MainActor required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func viewDidLoad() {
        super.viewDidLoad()
        addComponent(hostingViewController, pinToEdges: true)
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBar()
    }

    private func configureNavigationBar() {
        let titleConfig = WMFNavigationBarTitleConfig(
            title: viewModel.localizedStrings.settingTitle,
            customView: nil,
            alignment: .leadingCompact
        )
        let closeConfig = WMFNavigationBarCloseButtonConfig(
            text: viewModel.localizedStrings.doneButtonTitle,
            target: self,
            action: #selector(tappedDone),
            alignment: .trailing
        )
        configureNavigationBar(
            titleConfig: titleConfig,
            closeButtonConfig: closeConfig,
            profileButtonConfig: nil,
            tabsButtonConfig: nil,
            searchBarConfig: nil,
            hideNavigationBarOnScroll: false
        )
    }

    @objc func tappedDone() {
        dismiss(animated: true)
    }

}

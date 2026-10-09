import UIKit
import SwiftUI
import Combine

final public class WMFSettingsViewController: WMFComponentHostingController<WMFSettingsView>, WMFNavigationBarConfiguring {

    private let viewModel: WMFSettingsViewModel
    public let coordinatorDelegate: SettingsCoordinatorDelegate?

    public init(viewModel: WMFSettingsViewModel, coordinatorDelegate: SettingsCoordinatorDelegate?) {
        self.viewModel = viewModel
        self.coordinatorDelegate = coordinatorDelegate
        super.init(rootView: WMFSettingsView(viewModel: viewModel))
        viewModel.coordinatorDelegate = coordinatorDelegate
    }

    @MainActor required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private var hasAppearedBefore = false

	/// Exposes the settings container to UI tests in every supported language.
	public override func viewDidLoad() {
		super.viewDidLoad()
		view.accessibilityIdentifier = AccessibilityIdentifiers.Settings.view
	}

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBar()
        if let values = coordinatorDelegate?.fetchDynamicValues() {
            viewModel.updateDynamicValues(
                primaryLanguage: values.primaryLanguage,
                readingPreferenceTheme: values.readingPreferenceTheme
            )
        }
        if hasAppearedBefore {
            Task {
                await viewModel.refreshSections()
            }
        }
        hasAppearedBefore = true
    }

    private func configureNavigationBar() {
        let titleConfig = WMFNavigationBarTitleConfig(
            title: viewModel.localizedStrings.settingTitle,
            customView: nil,
            alignment: .leadingLarge
        )

        let closeConfig = WMFLargeCloseButtonConfig(imageType: .prominentCheck, target: self, action: #selector(tappedDone), alignment: .trailing)

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

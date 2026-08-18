import UIKit
import SwiftUI
import WMFData
import WMFNativeLocalizations

public final class WMFEditingPreferencesSettingsViewController: WMFComponentHostingController<WMFEditingPreferencesSettingsView>, WMFNavigationBarConfiguring {

    private let viewModel: WMFEditingPreferencesSettingsViewModel

    public init(didSelectMode: ((WMFEditMode) -> Void)? = nil) {
        let viewModel = WMFEditingPreferencesSettingsViewModel(didSelectMode: didSelectMode)
        self.viewModel = viewModel
        super.init(rootView: WMFEditingPreferencesSettingsView(viewModel: viewModel))
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBar()
    }

    private func configureNavigationBar() {
        let titleConfig = WMFNavigationBarTitleConfig(
            title: viewModel.title,
            customView: nil,
            alignment: .centerCompact
        )
        
        configureNavigationBar(
            titleConfig: titleConfig,
            closeButtonConfig: nil,
            profileButtonConfig: nil,
            tabsButtonConfig: nil,
            searchBarConfig: nil,
            hideNavigationBarOnScroll: false
        )
    }
}

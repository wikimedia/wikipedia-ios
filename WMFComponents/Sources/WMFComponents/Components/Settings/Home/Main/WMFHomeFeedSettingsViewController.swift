import UIKit
import SwiftUI
import WMFNativeLocalizations

public final class WMFHomeFeedSettingsViewController: WMFComponentHostingController<WMFHomeFeedSettingsView>, WMFNavigationBarConfiguring {

    private let viewModel: WMFHomeFeedSettingsViewModel

    public init(didTapCommunityModules: (() -> Void)? = nil, didTapForYouModules: (() -> Void)? = nil, didTapForYouWhatsDriving: (() -> Void)? = nil) {
        let viewModel = WMFHomeFeedSettingsViewModel(didTapCommunityModules: didTapCommunityModules, didTapForYouModules: didTapForYouModules, didTapForYouWhatsDriving: didTapForYouWhatsDriving)
        self.viewModel = viewModel
        super.init(rootView: WMFHomeFeedSettingsView(viewModel: viewModel))
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBar()
    }

    private func configureNavigationBar() {
        let titleConfig = WMFNavigationBarTitleConfig(title: viewModel.title, customView: nil, alignment: .centerCompact)
        configureNavigationBar(titleConfig: titleConfig, closeButtonConfig: nil, profileButtonConfig: nil, tabsButtonConfig: nil, searchBarConfig: nil, hideNavigationBarOnScroll: false)
    }
}

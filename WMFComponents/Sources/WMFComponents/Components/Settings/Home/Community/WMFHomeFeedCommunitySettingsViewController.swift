import UIKit

public final class WMFHomeFeedCommunitySettingsViewController: WMFComponentHostingController<WMFHomeFeedCommunitySettingsView>, WMFNavigationBarConfiguring {

    private let viewModel: WMFHomeFeedCommunitySettingsViewModel

    public init(viewModel: WMFHomeFeedCommunitySettingsViewModel) {
        self.viewModel = viewModel
        super.init(rootView: WMFHomeFeedCommunitySettingsView(viewModel: viewModel))
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
    

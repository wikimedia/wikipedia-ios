import UIKit
import WMFData

public final class WMFHomeFeedInterestsSettingsViewController: WMFComponentHostingController<WMFHomeFeedInterestsSettingsView>, WMFNavigationBarConfiguring {

    private let viewModel: WMFHomeFeedInterestsSettingsViewModel

    public init(viewModel: WMFHomeFeedInterestsSettingsViewModel) {
        self.viewModel = viewModel
        super.init(rootView: WMFHomeFeedInterestsSettingsView(viewModel: viewModel))
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBar()
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        guard isMovingFromParent || isBeingDismissed else { return }
        if viewModel.hasChanges {
            NotificationCenter.default.post(name: WMFNSNotification.forYouInterestsDidChange, object: nil)
        }
    }

    private func configureNavigationBar() {
        let titleConfig = WMFNavigationBarTitleConfig(title: viewModel.title, customView: nil, alignment: .centerCompact)
        configureNavigationBar(titleConfig: titleConfig, closeButtonConfig: nil, profileButtonConfig: nil, tabsButtonConfig: nil, searchBarConfig: nil, hideNavigationBarOnScroll: false)
    }
}

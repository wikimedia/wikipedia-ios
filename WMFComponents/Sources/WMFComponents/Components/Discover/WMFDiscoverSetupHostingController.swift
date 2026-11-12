import UIKit
import SwiftUI

public final class WMFDiscoverSetupHostingController: WMFComponentHostingController<WMFDiscoverSetupView>, WMFNavigationBarConfiguring {

    public let viewModel: WMFDiscoverSetupViewModel

    public init(viewModel: WMFDiscoverSetupViewModel) {
        self.viewModel = viewModel
        super.init(rootView: WMFDiscoverSetupView(viewModel: viewModel))
        configureHidesBottomBarWhenPushed()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: - Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = theme.paperBackground
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBar()
    }

    /// Back pops the screen. The list that takes its place removes it while another screen covers
    /// it, and that removal sends no appearance callback.
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isMovingFromParent {
            viewModel.viewDidGoBack()
        }
    }

    public override func appEnvironmentDidChange() {
        super.appEnvironmentDidChange()
        view.backgroundColor = theme.paperBackground
    }

    // MARK: - Navigation bar

    /// On onboarding the question is the screen's own title, so the bar shows only the back
    /// button. From Settings the bar shows "How Discover is built", like on Android.
    private func configureNavigationBar() {
        let titleConfig: WMFNavigationBarTitleConfig
        switch viewModel.presentation {
        case .onboarding:
            titleConfig = WMFNavigationBarTitleConfig(title: WMFDiscoverSetupView.title, customView: nil, alignment: .hidden)
        case .settings:
            titleConfig = WMFNavigationBarTitleConfig(title: WMFDiscoverSettingsViewModel.sourceTitle, customView: nil, alignment: .centerCompact)
        }
        configureNavigationBar(
            titleConfig: titleConfig,
            backButtonConfig: WMFNavigationBarBackButtonConfig(needsCustomTruncateBackButtonTitle: false, backButtonDisplayMode: .minimal),
            closeButtonConfig: nil,
            profileButtonConfig: nil,
            tabsButtonConfig: nil,
            searchBarConfig: nil,
            hideNavigationBarOnScroll: false
        )
    }
}

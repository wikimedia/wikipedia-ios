import UIKit
import SwiftUI

public final class WMFDiscoverSettingsHostingController: WMFComponentHostingController<WMFDiscoverSettingsView>, WMFNavigationBarConfiguring {

    public let viewModel: WMFDiscoverSettingsViewModel

    public init(viewModel: WMFDiscoverSettingsViewModel) {
        self.viewModel = viewModel
        super.init(rootView: WMFDiscoverSettingsView(viewModel: viewModel))
        configureHidesBottomBarWhenPushed()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: - Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = theme.midBackground
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBar()

        // The source screen and the interests screen change the settings behind this screen.
        if !isMovingToParent {
            viewModel.refresh()
        }
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent || isBeingDismissed || navigationController?.isBeingDismissed == true {
            viewModel.didLeave?()
        }
    }

    public override func appEnvironmentDidChange() {
        super.appEnvironmentDidChange()
        view.backgroundColor = theme.midBackground
    }

    // MARK: - Navigation bar

    private func configureNavigationBar() {
        let titleConfig = WMFNavigationBarTitleConfig(title: WMFDiscoverReadingListView.title, customView: nil, alignment: .centerCompact)
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

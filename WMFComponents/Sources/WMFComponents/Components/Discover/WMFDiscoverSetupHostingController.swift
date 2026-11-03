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

    public override func appEnvironmentDidChange() {
        super.appEnvironmentDidChange()
        view.backgroundColor = theme.paperBackground
    }

    // MARK: - Navigation bar

    /// The question is the screen's own title, so the bar shows only the back button.
    private func configureNavigationBar() {
        let titleConfig = WMFNavigationBarTitleConfig(title: WMFDiscoverSetupView.title, customView: nil, alignment: .hidden)
        configureNavigationBar(
            titleConfig: titleConfig,
            backButtonConfig: WMFNavigationBarBackButtonConfig(needsCustomTruncateBackButtonTitle: true),
            closeButtonConfig: nil,
            profileButtonConfig: nil,
            tabsButtonConfig: nil,
            searchBarConfig: nil,
            hideNavigationBarOnScroll: false
        )
    }
}

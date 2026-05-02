import UIKit
import SwiftUI

public final class WMFTrendingViewController: WMFComponentHostingController<WMFTrendingView>, WMFNavigationBarConfiguring {

    private let viewModel: WMFTrendingViewModel

    public init(viewModel: WMFTrendingViewModel) {
        self.viewModel = viewModel
        super.init(rootView: WMFTrendingView(viewModel: viewModel))
    }

    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBar()
    }

    private func configureNavigationBar() {
        let titleConfig = WMFNavigationBarTitleConfig(
            title: viewModel.localizedStrings.navigationTitle,
            customView: nil,
            alignment: .leadingLarge
        )
        let closeConfig = WMFLargeCloseButtonConfig(imageType: .prominentCheck, target: self, action: #selector(tappedClose), alignment: .trailing)
        configureNavigationBar(
            titleConfig: titleConfig,
            closeButtonConfig: closeConfig,
            profileButtonConfig: nil,
            tabsButtonConfig: nil,
            searchBarConfig: nil,
            hideNavigationBarOnScroll: false
        )
    }

    @objc private func tappedClose() {
        dismiss(animated: true)
    }
}

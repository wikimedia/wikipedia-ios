import UIKit
import SwiftUI

public final class WMFTrendingCountryViewController: WMFComponentHostingController<WMFTrendingCountryView>, WMFNavigationBarConfiguring {

    private let viewModel: WMFTrendingCountryViewModel

    public init(viewModel: WMFTrendingCountryViewModel) {
        self.viewModel = viewModel
        super.init(rootView: WMFTrendingCountryView(viewModel: viewModel))
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
            title: viewModel.countryName,
            customView: nil,
            alignment: .leadingLarge
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

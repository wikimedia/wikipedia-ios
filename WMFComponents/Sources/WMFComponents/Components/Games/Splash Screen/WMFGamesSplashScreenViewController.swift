import SwiftUI
import UIKit

public final class WMFGamesSplashScreenViewController: WMFComponentHostingController<WMFGamesSplashScreenView>, WMFNavigationBarConfiguring {

    // MARK: - Properties

    private let viewModel: WMFGamesSplashScreenViewModel

    // MARK: - Initialization

    public init(viewModel: WMFGamesSplashScreenViewModel) {
        self.viewModel = viewModel
        let view = WMFGamesSplashScreenView(viewModel: viewModel)
        super.init(rootView: view)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: - Lifecycle

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBarForSplash()
    }

    public override func appEnvironmentDidChange() {
        super.appEnvironmentDidChange()
        configureNavigationBarForSplash()
    }

    // MARK: - Navigation Bar

    private func configureNavigationBarForSplash() {
        let titleConfig = WMFNavigationBarTitleConfig(
            title: viewModel.dateString ?? viewModel.title,
            customView: nil,
            alignment: .centerCompact
        )

        let closeConfig = WMFLargeCloseButtonConfig(
            imageType: .plainX,
            target: self,
            action: #selector(didTapClose),
            alignment: .leading
        )

        configureNavigationBar(
            titleConfig: titleConfig,
            closeButtonConfig: closeConfig,
            profileButtonConfig: nil,
            tabsButtonConfig: nil,
            searchBarConfig: nil,
            hideNavigationBarOnScroll: false
        )

        let moreButton = UIBarButtonItem(
            image: WMFSFSymbolIcon.for(symbol: .ellipsis),
            style: .plain,
            target: self,
            action: #selector(didTapMore)
        )
        navigationItem.rightBarButtonItem = moreButton

        // Make the navigation bar transparent so the game background shows through,
        // with white title and button tints regardless of the current theme.
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [.foregroundColor: WMFColor.white]
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactAppearance = appearance
        navigationController?.navigationBar.tintColor = .white
    }

    // MARK: - Actions

    @objc private func didTapClose() {
        navigationController?.dismiss(animated: true)
        viewModel.didTapClose?() // any additional handling
    }

    @objc private func didTapMore() {
        viewModel.didTapMore?()
    }
}

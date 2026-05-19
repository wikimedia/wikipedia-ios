import SwiftUI
import UIKit

/// Hosting controller for `WMFGamesSplashScreenView`.
/// Configures the transparent/colored navigation bar so the splash background
/// extends behind it, and surfaces close + more (ellipsis) bar button items.
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
            title: viewModel.title,
            customView: viewModel.dateString.map { makeDatePillView(title: $0) },
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

        // The protocol handles the close button; set the more button on the trailing side.
        let moreButton = UIBarButtonItem(
            image: WMFSFSymbolIcon.for(symbol: .ellipsisCircle),
            style: .plain,
            target: self,
            action: #selector(didTapMore)
        )
        navigationItem.rightBarButtonItem = moreButton

        // Make the navigation bar transparent so the game background shows through.
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactAppearance = appearance
    }

    private func makeDatePillView(title: String) -> UIView {
        let label = UILabel()
        label.text = title
        label.font = WMFFont.for(.semiboldSubheadline)
        label.textColor = .white
        label.textAlignment = .center
        label.sizeToFit()

        let container = UIView()
        container.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        container.layer.cornerRadius = 14
        container.clipsToBounds = true

        container.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: 6),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -6)
        ])
        container.sizeToFit()
        return container
    }

    // MARK: - Actions

    @objc private func didTapClose() {
        dismiss(animated: true)
        viewModel.didTapClose?()
    }

    @objc private func didTapMore() {
        viewModel.didTapMore?()
    }
}

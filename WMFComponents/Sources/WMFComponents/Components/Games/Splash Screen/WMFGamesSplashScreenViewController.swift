import SwiftUI
import UIKit

/// Hosting controller for `WMFGamesSplashScreenView`.
/// Configures the transparent/colored navigation bar so the splash background
/// extends behind it, and surfaces close + more (ellipsis) bar button items.
public final class WMFGamesSplashScreenViewController: WMFComponentHostingController<WMFGamesSplashScreenView> {

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

    public override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
    }

    public override func appEnvironmentDidChange() {
        super.appEnvironmentDidChange()
        // Keep the navigation bar transparent so the game background shows through.
        configureNavigationBar()
    }

    // MARK: - Navigation Bar

    private func configureNavigationBar() {
        // Temp nav bar
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactAppearance = appearance

        let closeButton = UIBarButtonItem(
            image: WMFSFSymbolIcon.for(symbol: .closeCircleFill),
            style: .plain,
            target: self,
            action: #selector(didTapClose)
        )
        closeButton.tintColor = UIColor.white
        navigationItem.leftBarButtonItem = closeButton

        let moreButton = UIBarButtonItem(
            image: WMFSFSymbolIcon.for(symbol: .ellipsisCircle),
            style: .plain,
            target: self,
            action: #selector(didTapMore)
        )
        moreButton.tintColor = UIColor.white
        navigationItem.rightBarButtonItem = moreButton


        if let dateString = viewModel.dateString {
            navigationItem.titleView = makeDatePillView(title: dateString)
        }
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
        viewModel.didTapClose?()
    }

    @objc private func didTapMore() {
        viewModel.didTapMore?()
    }
}


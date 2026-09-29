import SwiftUI
import UIKit

/// Hosts the sheet of passages found inside articles. Present it inside a
/// `WMFComponentNavigationController`: the Beta badge and the close button are bar items, so
/// the system can move them to the vertical bar of iPhone Duo.
public final class WMFSemanticSearchResultsHostingController: WMFComponentHostingController<WMFSemanticSearchResultsView>, WMFNavigationBarConfiguring {

    private let viewModel: WMFSemanticSearchResultsViewModel

    public init(viewModel: WMFSemanticSearchResultsViewModel) {
        self.viewModel = viewModel
        super.init(rootView: WMFSemanticSearchResultsView(viewModel: viewModel))
    }

    @available(*, unavailable)
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBar()
    }

    private func configureNavigationBar() {
        let titleConfig = WMFNavigationBarTitleConfig(title: "", customView: nil, alignment: .hidden)
        let closeConfig = WMFLargeCloseButtonConfig(imageType: .plainX, target: self, action: #selector(tappedClose), alignment: .trailing)

        configureNavigationBar(
            titleConfig: titleConfig,
            closeButtonConfig: closeConfig,
            profileButtonConfig: nil,
            tabsButtonConfig: nil,
            searchBarConfig: nil,
            hideNavigationBarOnScroll: false
        )

        navigationItem.leftBarButtonItem = UIBarButtonItem.hostingBarButtonItem(rootView: WMFBetaBadge(label: viewModel.betaLabel))
        navigationItem.rightBarButtonItem?.accessibilityIdentifier = AccessibilityIdentifiers.Search.semanticSearchResultsCloseButton
    }

    @objc private func tappedClose() {
        viewModel.close()
    }
}

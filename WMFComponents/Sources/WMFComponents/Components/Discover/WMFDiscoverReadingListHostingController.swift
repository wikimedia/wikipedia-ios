import UIKit
import SwiftUI

public final class WMFDiscoverReadingListHostingController: WMFComponentHostingController<WMFDiscoverReadingListView>, WMFNavigationBarConfiguring {

    public let viewModel: WMFDiscoverReadingListViewModel

    public init(viewModel: WMFDiscoverReadingListViewModel) {
        self.viewModel = viewModel
        super.init(rootView: WMFDiscoverReadingListView(viewModel: viewModel))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: - Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = theme.paperBackground
        viewModel.load()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBar()

        // Back from the Discover settings. A new source or article count regenerates the list.
        if !isMovingToParent {
            viewModel.reloadIfGenerationDue()
        }
    }

    public override func appEnvironmentDidChange() {
        super.appEnvironmentDidChange()
        view.backgroundColor = theme.paperBackground
        configureNavigationBar()
    }

    // MARK: - Navigation bar

    /// The bar is transparent over the collage and shows no title. The page body has the title. The Back button on the next screen shows only the chevron.
    private func configureNavigationBar() {
        let titleConfig = WMFNavigationBarTitleConfig(
            title: WMFDiscoverReadingListView.title,
            customView: nil,
            alignment: .hidden
        )
        
        configureNavigationBar(
            titleConfig: titleConfig,
            backButtonConfig: WMFNavigationBarBackButtonConfig(needsCustomTruncateBackButtonTitle: false, backButtonDisplayMode: .minimal),
            closeButtonConfig: nil,
            profileButtonConfig: nil,
            tabsButtonConfig: nil,
            searchBarConfig: nil,
            hideNavigationBarOnScroll: false
        )

        let scrollEdgeAppearance = UINavigationBarAppearance()
        scrollEdgeAppearance.configureWithTransparentBackground()

        let standardAppearance = UINavigationBarAppearance()
        if #available(iOS 26.0, *) {
            standardAppearance.configureWithDefaultBackground()
        } else {
            standardAppearance.configureWithOpaqueBackground()
            standardAppearance.backgroundColor = theme.paperBackground
        }
        standardAppearance.shadowColor = .clear

        navigationItem.scrollEdgeAppearance = scrollEdgeAppearance
        navigationItem.standardAppearance = standardAppearance
        navigationItem.compactAppearance = standardAppearance
        navigationItem.compactScrollEdgeAppearance = scrollEdgeAppearance
    }
}

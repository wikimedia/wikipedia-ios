import SwiftUI
import UIKit

public final class WMFYearInReviewAnnouncementHostingController: WMFComponentHostingController<WMFYearInReviewAnnouncementView>, WMFNavigationBarConfiguring {

    private let viewModel: WMFYearInReviewAnnouncementViewModel

    public init(viewModel: WMFYearInReviewAnnouncementViewModel) {
        self.viewModel = viewModel
        super.init(rootView: WMFYearInReviewAnnouncementView(viewModel: viewModel))
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    public override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBar()
        (navigationController as? WMFComponentNavigationController)?.setTransparentAppearance(true)
    }

    // MARK: - Navigation bar

    /// Same layout as the slides: close, the W, and the more menu.
    private func configureNavigationBar() {
        let titleConfig = WMFNavigationBarTitleConfig(
            title: "",
            customView: WMFYearInReviewNavigationItems.makeTitleView(
                accessibilityLabel: viewModel.localizedStrings.wIconAccessibilityLabel,
                tintColor: viewModel.contentColor
            ),
            alignment: .centerCompact
        )

        let closeConfig = WMFLargeCloseButtonConfig(
            imageType: .plainX,
            target: self,
            action: #selector(tappedClose),
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

        navigationItem.rightBarButtonItem = WMFYearInReviewNavigationItems.makeMoreButton(
            strings: WMFYearInReviewNavigationItems.MoreMenuStrings(
                moreButtonAccessibilityLabel: viewModel.localizedStrings.moreButtonAccessibilityLabel,
                learnMoreTitle: viewModel.localizedStrings.learnMoreButtonTitle,
                aboutInsightsTitle: viewModel.localizedStrings.aboutInsightsButtonTitle
            ),
            tintColor: viewModel.contentColor,
            onLearnMore: { [weak self] in self?.viewModel.tappedLearnMore() },
            onAboutInsights: { [weak self] in self?.viewModel.tappedAboutInsights() }
        )

        navigationItem.leftBarButtonItem?.tintColor = viewModel.contentColor
        navigationItem.leftBarButtonItem?.accessibilityLabel = viewModel.localizedStrings.closeButtonAccessibilityLabel
    }

    @objc private func tappedClose() {
        viewModel.tappedClose()
    }
}

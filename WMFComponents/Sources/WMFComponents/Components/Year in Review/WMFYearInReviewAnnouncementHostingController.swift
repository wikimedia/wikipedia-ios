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

    /// Same navigation bar as the slides.
    private func configureNavigationBar() {
        WMFYearInReviewNavigationItems.configure(
            self,
            strings: WMFYearInReviewNavigationItems.Strings(
                wIconAccessibilityLabel: viewModel.localizedStrings.wIconAccessibilityLabel,
                closeButtonAccessibilityLabel: viewModel.localizedStrings.closeButtonAccessibilityLabel,
                moreButtonAccessibilityLabel: viewModel.localizedStrings.moreButtonAccessibilityLabel,
                learnMoreTitle: viewModel.localizedStrings.learnMoreButtonTitle,
                aboutInsightsTitle: viewModel.localizedStrings.aboutInsightsButtonTitle,
                shareFeedbackTitle: viewModel.localizedStrings.shareFeedbackButtonTitle
            ),
            tintColor: viewModel.contentColor,
            closeAction: #selector(tappedClose),
            onLearnMore: { [weak self] in self?.viewModel.tappedLearnMore() },
            onAboutInsights: { [weak self] in self?.viewModel.tappedAboutInsights() },
            onShareFeedback: { [weak self] in self?.viewModel.tappedShareFeedback() }
        )
    }

    @objc private func tappedClose() {
        viewModel.tappedClose()
    }
}

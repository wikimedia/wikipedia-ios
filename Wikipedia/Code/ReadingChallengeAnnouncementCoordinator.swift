import UIKit
import WMFData
import WMFComponents

@MainActor
final class ReadingChallengeAnnouncementCoordinator: NSObject, Coordinator {

    var navigationController: UINavigationController
    private let dataStore: MWKDataStore
    private let theme: Theme

    var onDismiss: (() -> Void)?
    var onEnroll: (() -> Void)?

    init(navigationController: UINavigationController, dataStore: MWKDataStore, theme: Theme) {
        self.navigationController = navigationController
        self.dataStore = dataStore
        self.theme = theme
    }

    @discardableResult
    func start() -> Bool {

        let firstItem = WMFOnboardingViewModel.WMFOnboardingCellViewModel(
            icon: WMFSFSymbolIcon.for(symbol: .bookPagesFill),
            title: WMFLocalizedString(
                "reading-challenge-announcement-item1-title",
                value: "Read 1 article a day for 25 days",
                comment: "Title for reading challenge onboarding first item."
            ),
            subtitle: WMFLocalizedString(
                "reading-challenge-announcement-item1-subtitle",
                value: "Join the challenge anytime between 1 May and 31 May, complete your 25 days on your own timeline.",
                comment: "Subtitle for reading challenge onboarding first item."
            ),
            fillIconBackground: false
        )

        let secondItem = WMFOnboardingViewModel.WMFOnboardingCellViewModel(
            icon: WMFSFSymbolIcon.for(symbol: .appGiftFill),
            title: WMFLocalizedString(
                "reading-challenge-announcement-item2-title",
                value: "Win prizes",
                comment: "Title for reading challenge onboarding second item."
            ),
            subtitle: WMFLocalizedString(
                "reading-challenge-announcement-item2-subtitle",
                value: "Complete a 25-day reading streak while the challenge is live to win special prizes.",
                comment: "Subtitle for reading challenge onboarding second item."
            ),
            fillIconBackground: false
        )

        let thirdItem = WMFOnboardingViewModel.WMFOnboardingCellViewModel(
            icon: WMFSFSymbolIcon.for(symbol: .widgetAdd),
            title: WMFLocalizedString(
                "reading-challenge-announcement-item3-title",
                value: "Install the widget",
                comment: "Title for reading challenge onboarding third item."
            ),
            subtitle: WMFLocalizedString(
                "reading-challenge-announcement-item3-subtitle",
                value: "Get helpful reminders and motivation with our adorable birthday mascot Baby Globe.",
                comment: "Subtitle for reading challenge onboarding third item."
            ),
            fillIconBackground: false
        )

        let subtitle = WMFLocalizedString(
            "reading-challenge-announcement-subtitle",
            value: "Your reading history is kept protected. Reading insights are calculated using locally stored data on your device.",
            comment: "Notice about privacy for reading challenge"
        )

        let onboardingViewModel = WMFOnboardingViewModel(
            title: WMFLocalizedString(
                "reading-challenge-announcement-title",
                value: "Celebrate Wikipedia's 25th birthday by joining the 25-day reading challenge!",
                comment: "Title for the reading challenge onboarding view."
            ),
            cells: [firstItem, secondItem, thirdItem],
            primaryButtonTitle: WMFLocalizedString(
                "reading-challenge-announcement-cta",
                value: "Join the challenge",
                comment: "Primary button title"
            ),
            secondaryButtonTitle: WMFLocalizedString(
                "reading-challenge-announcement-secondary-cta",
                value: "Learn more",
                comment: "Secondary button title"
            ),
            subtitle: subtitle
        )

        let onboardingController = WMFOnboardingViewController(viewModel: onboardingViewModel)
        onboardingController.delegate = self
        onboardingController.closeButtonAction = { [weak self] in
            self?.navigationController.presentedViewController?.dismiss(animated: true) {
                self?.onDismiss?()
            }
        }

        let navController = WMFComponentNavigationController(rootViewController: onboardingController, modalPresentationStyle: .pageSheet)

        // Mark seen immediately on presentation so it won't show again
        // even if user backgrounds the app or swipe-dismisses
        markSeen()

        navigationController.present(navController, animated: true) {
            UIAccessibility.post(notification: .layoutChanged, argument: nil)
        }

        return true
    }

    private func markSeen() {
        Task {
            await WMFActivityTabDataController.shared.setHasSeenFullPageAnnouncement()
        }
    }

    private func enroll() {
        Task {
            await WMFActivityTabDataController.shared.enrollInReadingChallenge()
            await MainActor.run {
                WidgetController.shared.reloadReadingChallengeWidget()
            }
        }
    }

    var learnMoreURL: URL? {
        guard let appLanguage = WMFDataEnvironment.current.primaryAppLanguage else {
            return nil
        }
        return WMFProject.mediawiki.translatedHelpURL(pathComponents: ["Wikimedia Apps", "Team", "25th Birthday Reading Challenge"], section: nil, language: appLanguage)
    }
}

// MARK: - WMFOnboardingViewDelegate

@MainActor
extension ReadingChallengeAnnouncementCoordinator: WMFOnboardingViewDelegate {

    func onboardingViewDidClickPrimaryButton() {
        enroll()
        navigationController.presentedViewController?.dismiss(animated: true) { [weak self] in
            self?.onEnroll?()
        }
    }

    func onboardingViewDidClickSecondaryButton() {
        guard let url = learnMoreURL else { return }

        let config = SinglePageWebViewController.StandardConfig(
            url: url,
            useSimpleNavigationBar: true
        )

        let webVC = SinglePageWebViewController(
            configType: .standard(config),
            theme: self.theme
        )

        navigationController.presentedViewController?.children.first.flatMap { $0 as? UINavigationController }?.pushViewController(webVC, animated: true)
        ?? (navigationController.presentedViewController as? UINavigationController)?.pushViewController(webVC, animated: true)
    }
}

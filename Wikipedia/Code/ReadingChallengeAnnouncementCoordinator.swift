import UIKit
import WMFData
import WMFComponents

@MainActor
final class ReadingChallengeAnnouncementCoordinator: NSObject, Coordinator {
    var navigationController: UINavigationController
    private let dataStore: MWKDataStore
    private let theme: Theme

    init(navigationController: UINavigationController, dataStore: MWKDataStore, theme: Theme) {
        self.navigationController = navigationController
        self.dataStore = dataStore
        self.theme = theme
    }

    @discardableResult
    func start() -> Bool {
        let firstItem = WMFOnboardingViewModel.WMFOnboardingCellViewModel(
            icon: WMFSFSymbolIcon.for(symbol: .bookPagesFill),
            title: WMFLocalizedString("reading-challenge-announcement-item1-title", value: "Read 1 article a day for 25 days", comment: "Title for reading challenge onboarding first item."),
            subtitle: WMFLocalizedString("reading-challenge-announcement-item1-subtitle", value: "Join the challenge anytime between 1 May and 31 May, complete your 25 days on your own timeline.", comment: "Subtitle for reading challenge onboarding first item."),
            fillIconBackground: false
        )

        let secondItem = WMFOnboardingViewModel.WMFOnboardingCellViewModel(
            icon: WMFSFSymbolIcon.for(symbol: .appGiftFill),
            title: WMFLocalizedString("reading-challenge-announcement-item2-title", value: "Win prizes", comment: "Title for reading challenge onboarding second item."),
            subtitle: WMFLocalizedString("reading-challenge-announcement-item2-subtitle", value: "Complete a 25 day reading streak while the challenge is live to win special prizes.", comment: "Subtitle for reading challenge onboarding second item."),
            fillIconBackground: false
        )

        let thirdItem = WMFOnboardingViewModel.WMFOnboardingCellViewModel(
            icon: WMFSFSymbolIcon.for(symbol: .widgetAdd),
            title: WMFLocalizedString("reading-challenge-announcement-item3-title", value: "Install the widget", comment: "Title for reading challenge onboarding third item."),
            subtitle: WMFLocalizedString("reading-challenge-announcement-item3-subtitle", value: "Get helpful reminders and motivation with our adorable birthday mascot Baby Globe.", comment: "Subtitle for reading challenge onboarding third item."),
            fillIconBackground: false
        )

        let subtitle = WMFLocalizedString("reading-challenge-announcement-subtitle", value: "Your reading history is kept protected. Reading insights are calculated using locally stored data on your device.", comment: "Notice about privacy for reading challenge")

        let onboardingViewModel = WMFOnboardingViewModel(
            title: WMFLocalizedString("reading-challenge-announcement-title", value: "Celebrate Wikipedia's 25th birthday by joining the 25-day reading challenge!", comment: "Title for the reading challenge onboarding view."),
            cells: [firstItem, secondItem, thirdItem],
            primaryButtonTitle: WMFLocalizedString("reading-challenge-announcement-cta", value: "Join the challenge", comment: "Primary button title for the reading challenge onboarding view."),
            secondaryButtonTitle: WMFLocalizedString("reading-challenge-announcement-secondary-cta", value: "Learn more", comment: "Secondary button title for the reading challenge onboarding view."),
            subtitle: subtitle
        )

        let onboardingController = WMFOnboardingViewController(viewModel: onboardingViewModel)
        onboardingController.delegate = self
        let doneButton = UIBarButtonItem(image: WMFSFSymbolIcon.for(symbol: .xMark), style: .plain, target: self, action: #selector(doneTapped))
        onboardingController.navigationItem.rightBarButtonItem = doneButton
        let navController = UINavigationController(rootViewController: onboardingController)
        navigationController.present(navController, animated: true) {
            UIAccessibility.post(notification: .layoutChanged, argument: nil)
        }
        return true
    }

    @objc private func doneTapped() {
        navigationController.presentedViewController?.dismiss(animated: true)
    }

    private func markSeen() {
        Task {
            await WMFActivityTabDataController.shared.setHasSeenFullPageAnnouncement()
        }
    }

    var learnMoreURL: URL? {
        var languageCodeSuffix = ""
        if let primaryAppLanguageCode = dataStore.languageLinkController.appLanguage?.languageCode {
            languageCodeSuffix = primaryAppLanguageCode
        }
        return URL(string: "https://www.mediawiki.org/wiki/Special:MyLanguage/Wikipedia:25/Reading_Challenge?uselang=\(languageCodeSuffix)")
    }
}

extension ReadingChallengeAnnouncementCoordinator: @preconcurrency WMFOnboardingViewDelegate {
    func onboardingViewDidClickPrimaryButton() {
        markSeen()
        navigationController.presentedViewController?.dismiss(animated: true)
    }

    func onboardingViewDidClickSecondaryButton() {
        markSeen()
        navigationController.presentedViewController?.dismiss(animated: true) { [weak self] in
            guard let self, let url = learnMoreURL else { return }
            let config = SinglePageWebViewController.StandardConfig(url: url, useSimpleNavigationBar: true)
            let webVC = SinglePageWebViewController(configType: .standard(config), theme: theme)
            let newNavigationVC = WMFComponentNavigationController(rootViewController: webVC, modalPresentationStyle: .formSheet)
            navigationController.present(newNavigationVC, animated: true)
        }
    }
}

extension WMFActivityTabDataController {
    func setHasSeenFullPageAnnouncement() {
        hasSeenFullPageReadingChallengeAnnouncement2026 = true
    }
}

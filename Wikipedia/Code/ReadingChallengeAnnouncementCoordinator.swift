import UIKit
import WMFData
import WMFComponents
import WMF
import WMFNativeLocalizations
import WMFTestKitchen

@MainActor
final class ReadingChallengeAnnouncementCoordinator: NSObject, Coordinator {

    var navigationController: UINavigationController
    private let dataStore: MWKDataStore
    private let theme: Theme
    
    // If announcement is displaying from the user tapping the widget join button, set to true.
    // This will internally ignore the hasAlreadySeen user default, and prevent the followup widget announcement from displaying after joining.
    private let fromWidgetJoinChallengeButton: Bool
    
    private let isLoggedIn: Bool
    
    private lazy var widgetInstrument: InstrumentImpl = {
        TestKitchenAdapter.shared.client.getInstrument(name: "apps-widgetchallenge")
            .setDefaultActionSource("widget_challenge_announce")
            .startFunnel(name: "widget_challenge")
    }()

    init(navigationController: UINavigationController, dataStore: MWKDataStore, theme: Theme, fromWidgetJoinChallengeButton: Bool, isLoggedIn: Bool) {
        self.navigationController = navigationController
        self.dataStore = dataStore
        self.theme = theme
        self.fromWidgetJoinChallengeButton = fromWidgetJoinChallengeButton
        self.isLoggedIn = isLoggedIn
    }

    // This action will be called when this coordinator has finished evaluating, whether it presents something or not. It gives callers a chance to run followup code such as presenting less-important modals.
    // The boolean flag indicates if the coordinator did present something or not:
        // If it determines the announcement should not present (either because of date or has already seen the announcement), this completion will run with the FALSE boolean.
        // If announcement did present, it is called after all modals (both reading challenge announcement and widget announcement) have been dismissed. In this case it will run with the TRUE boolean.
    
    var onComplete: ((Bool) -> Void)?
    
    @discardableResult
    func start() -> Bool {
        
        Task { [weak self] in
            
            guard let self else { return }
            
            if fromWidgetJoinChallengeButton { // go straight to announcement, don't gate on any other logic
                presentFullPageAnnouncement()
            } else {
                
                // Check that announcement has not already been seen and dates are valid.
                guard await WMFActivityTabDataController.shared.shouldShowReadingChallengeAnnouncement() else {
                    self.onComplete?(false)
                    return
                }
                
                presentFullPageAnnouncement()
            }
        }

        return true
    }
    
    // MARK: - Full page announcement
    
    private func presentFullPageAnnouncement() {
        
        let formatter = DateFormatter.wmfMonthDayDateFormatter
        let startText = formatter.string(from: ReadingChallengeStateConfig.startDate)
        let endText = formatter.string(from: ReadingChallengeStateConfig.endDate)
        
        let firstItem = WMFOnboardingViewModel.WMFOnboardingCellViewModel(
            icon: WMFSFSymbolIcon.for(symbol: .bookPagesFill),
            title: WMFLocalizedString(
                "reading-challenge-announcement-item1-title",
                value: "Read 1 article a day for 25 days",
                comment: "Title for reading challenge onboarding first item."
            ),
            subtitle: String.localizedStringWithFormat(WMFLocalizedString(
                "reading-challenge-announcement-item1-subtitle",
                value: "Join the challenge anytime between %1$@ and %2$@, complete your 25 days on your own timeline.",
                comment: "Subtitle for reading challenge onboarding first item. %1$@ is a localized start day and month name, %2$@ is a localized end date and month name."
            ), startText, endText),
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
            // Instrument: close (X) button tap on announcement screen
            self?.widgetInstrument.submitInteraction(action: "click", actionSource: "widget_challenge_announce", elementId: "close")
            self?.navigationController.presentedViewController?.dismiss(animated: true) { [weak self] in
                self?.onComplete?((true))
            }
        }

        let navController = WMFComponentNavigationController(rootViewController: onboardingController, modalPresentationStyle: .pageSheet)

        // Mark seen immediately on presentation so it won't show again
        // even if user backgrounds the app or swipe-dismisses
        markSeen()

        navigationController.present(navController, animated: true) {
            UIAccessibility.post(notification: .layoutChanged, argument: nil)
            // Instrument: impression on announcement view
            self.widgetInstrument.submitInteraction(action: "impression", actionSource: "widget_challenge_announce")
        }
    }

    private func markSeen() {
        Task {
            await WMFActivityTabDataController.shared.setHasSeenFullPageAnnouncement()
        }
    }

    private func enroll() {
        Task {
            await WMFActivityTabDataController.shared.setEnrolledInReadingChallenge(true)
            WidgetController.shared.reloadReadingChallengeWidget()
        }
    }

    var learnMoreURL: URL? {
        guard let appLanguage = WMFDataEnvironment.current.primaryAppLanguage else {
            return nil
        }
        return WMFProject.mediawiki.translatedHelpURL(pathComponents: ["Wikimedia Apps", "Team", "25th Birthday Reading Challenge"], section: nil, language: appLanguage)
    }
    
    // MARK: - Widget Announcement
    
    private func presentWidgetAnnouncement() {
        
        let viewModel = makeWidgetAnnouncementViewModel()

        // Wrap actions to dismiss the controller
        viewModel.primaryButtonAction = { [weak self] in
            // Instrument: "Got it" / primary CTA tap on widget install prompt
            self?.widgetInstrument.submitInteraction(action: "click", actionSource: "widget_challenge_install", elementId: "install_accept")
            self?.navigationController.presentedViewController?.dismiss(animated: true) { [weak self] in
                self?.onComplete?(true)
            }
        }
        viewModel.closeButtonAction = { [weak self] in
            // Instrument: close (X) button tap on widget install prompt
            self?.widgetInstrument.submitInteraction(action: "click", actionSource: "widget_challenge_install", elementId: "install_close")
            self?.navigationController.dismiss(animated: true) {
                self?.onComplete?(true)
            }
        }

        let controller = WMFFeatureAnnouncementViewController(viewModel: viewModel)

        if let sheet = controller.sheetPresentationController {
            if UIDevice.current.userInterfaceIdiom == .pad {
                sheet.detents = [.large()]
            } else {
                sheet.detents = [.medium(), .large()]
            }
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 16
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
        }

        controller.modalPresentationStyle = .pageSheet
        
        navigationController.present(controller, animated: true) { [weak self] in
            // Instrument: impression on widget install prompt
            self?.widgetInstrument.submitInteraction(action: "impression", actionSource: "widget_challenge_install")
        }
        
    }
    
    private func makeWidgetAnnouncementViewModel() -> WMFFeatureAnnouncementViewModel {
        WMFFeatureAnnouncementViewModel(
            title: WMFLocalizedString(
                "reading-challenge-widget-announcement-title",
                value: "Install the 25-day reading challenge widget",
                comment: "Title for the reading challenge widget announcement sheet."
            ),
            body: WMFLocalizedString(
                "reading-challenge-widget-announcement-body",
                value: "Baby Globe is cheering you on. Add the Reading Challenge widget to track your progress from your homescreen.",
                comment: "Body text for the reading challenge widget announcement sheet."
            ),
            primaryButtonTitle: CommonStrings.gotItButtonTitle,
            image: UIImage(named: "readingChallengeWidget"),
            backgroundImage: UIImage(named: "readingChallengeBackground"),
            backgroundImageHeight: 220,
            primaryButtonAction: {},
            closeButtonAction: nil
        )
    }
}

// MARK: - WMFOnboardingViewDelegate

@MainActor
extension ReadingChallengeAnnouncementCoordinator: WMFOnboardingViewDelegate {

    func onboardingViewDidClickPrimaryButton() {
        // Instrument: "Join the challenge" tap on announcement screen
        widgetInstrument.submitInteraction(action: "click", actionSource: "widget_challenge_announce", elementId: "join_challenge")

        if dataStore.authenticationManager.authStateIsPermanent {
            enroll()
            navigationController.presentedViewController?.dismiss(animated: true) { [weak self] in
                guard let self else { return }
                if !fromWidgetJoinChallengeButton {
                    self.presentWidgetAnnouncement()
                } else {
                    self.onComplete?(true)
                }
            }
        } else {
            let alert = UIAlertController(
                title: WMFLocalizedString("reading-challenge-login-title", value: "Log in to join the challenge", comment: "Title for alert that asks users to log in to join the reading challenge"),
                message: WMFLocalizedString("reading-challenge-login-message", value: "Log in or create an account to track your progress towards the reading challenge.", comment: "Message for alert that asks users to log in to join the reading challenge"),
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: CommonStrings.joinLoginTitle, style: .default) { [weak self] _ in
                guard let self else { return }
                // Instrument: "Log in / Join Wikipedia" tap on login alert
                self.widgetInstrument.submitInteraction(action: "click", actionSource: "widget_challenge_login", elementId: "login_join")
                self.navigationController.presentedViewController?.dismiss(animated: true) {
                    let loginCoordinator = LoginCoordinator(navigationController: self.navigationController, theme: self.theme, loggingCategory: .login)
                    
                    loginCoordinator.loginSuccessCompletion = { [weak self] in
                        guard let self else { return }
                        widgetInstrument
                            .submitInteraction(
                                action: "success",
                                actionSource: "login-join",
                                actionContext: ["invoke_source": "widget_challenge"]
                            )
                        if let loginVC = self.navigationController.presentedViewController {
                            loginVC.dismiss(animated: true) { [weak self] in
                                guard let self else { return }
                                enroll()
                                if !fromWidgetJoinChallengeButton {
                                    presentWidgetAnnouncement()
                                } else {
                                    onComplete?(true)
                                }
                            }
                        }
                    }
                    
                    loginCoordinator.createAccountSuccessCustomDismissBlock = { [weak self] in
                        guard let self else { return }
                        // Instrument: successful account creation invoked from widget_challenge context
                        // This fires in app_base funnel as: action=success, action_source=create_account_form,
                        // action_context={invoke_source: widget_challenge}, funnel_name=create_account
                        widgetInstrument
                            .submitInteraction(
                                action: "success",
                                actionSource: "create_account_form",
                                actionContext: ["invoke_source": "widget_challenge"]
                            )
                        if let createAccountVC = self.navigationController.presentedViewController {
                            createAccountVC.dismiss(animated: true) { [weak self] in
                                guard let self else { return }
                                enroll()
                                if !fromWidgetJoinChallengeButton {
                                    presentWidgetAnnouncement()
                                } else {
                                    onComplete?(true)
                                }
                            }
                        }
                    }
                    
                    loginCoordinator.start()
                }
            })
            alert.addAction(UIAlertAction(title: CommonStrings.cancelActionTitle, style: .cancel) { [weak self] _ in
                // Instrument: "No thanks" tap on login alert
                self?.widgetInstrument.submitInteraction(action: "click", actionSource: "widget_challenge_login", elementId: "no_thanks")
            })
            navigationController.presentedViewController?.present(alert, animated: true)
        }
    }
    
    func onboardingDidSwipeToDismiss() {
        // Instrument: swipe-to-dismiss on announcement screen
        widgetInstrument.submitInteraction(action: "click", actionSource: "widget_challenge_announce", elementId: "swipe_dismiss")
        self.onComplete?(true)
    }

    func onboardingViewDidClickSecondaryButton() {
        // Instrument: "Learn more" tap on announcement screen
        widgetInstrument.submitInteraction(action: "click", actionSource: "widget_challenge_announce", elementId: "learn_more")

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

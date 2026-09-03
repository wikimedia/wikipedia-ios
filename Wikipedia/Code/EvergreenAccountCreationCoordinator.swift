import UIKit
import WMFComponents
import WMFData
import WMFNativeLocalizations
import WMFTestKitchen

/// Presents the evergreen account creation prompt to logged-out readers who have become
/// account-ready, and reports what they did with it back to WMFData.
final class EvergreenAccountCreationCoordinator: NSObject, Coordinator {

    // MARK: - Coordinator Protocol Properties

    var navigationController: UINavigationController

    // MARK: - Properties

    private let theme: Theme
    private let dataStore: MWKDataStore
    private let context: WMFEvergreenAccountCreationDataController.PresentationContext

    private weak var promptNavigationController: WMFComponentNavigationController?

    /// The close button and the presentation delegate can both land here, so the first outcome wins.
    private var didRecordOutcome = false

    // TEMP - DESIGN REVIEW BRANCH ONLY, DO NOT MERGE.
    // Shows the prompt on every launch, tab switch and article, and records nothing, so the slides
    // can be reopened as often as needed.
    private static let alwaysShowForDesignReview = true

    private var dataController: WMFEvergreenAccountCreationDataController {
        WMFEvergreenAccountCreationDataController.shared
    }

    /// Matches Android's instrumentation for this prompt, so the two platforms are comparable:
    /// the `apps-authentication` instrument, a `create_account_encourage` funnel, an impression on
    /// presentation, and a click per button.
    private lazy var instrument: InstrumentImpl = {
        TestKitchenAdapter.shared.client.getInstrument(name: "apps-authentication")
            .startFunnel(name: "create_account_encourage")
    }()

    // MARK: - Lifecycle

    init(navigationController: UINavigationController, theme: Theme, dataStore: MWKDataStore, context: WMFEvergreenAccountCreationDataController.PresentationContext) {
        self.navigationController = navigationController
        self.theme = theme
        self.dataStore = dataStore
        self.context = context
    }

    // MARK: - Presentation

    @discardableResult
    func start() -> Bool {
        Task { await startIfEligible() }
        return true
    }

    /// Presents the prompt only if the reader is eligible right now.
    func startIfEligible() async {
        let presenter = navigationController.presentedViewController ?? navigationController

        if !Self.alwaysShowForDesignReview {
            guard await dataController.shouldShowPrompt(
                in: context,
                // Only a permanent account is excluded. A temporary account still sees the prompt.
                hasPermanentAccount: dataStore.authenticationManager.authStateIsPermanent,
                isAnotherPromptVisible: presenter.presentedViewController != nil
            ) else {
                return
            }
        }

        let slideData = await dataController.slideData()

        // Eligibility and the slide numbers are both awaited, so re-check that the screen is still
        // free before taking it.
        guard presenter.presentedViewController == nil else { return }

        present(slideData: slideData, from: presenter)
    }

    private func present(slideData: WMFEvergreenAccountCreationDataController.SlideData, from presenter: UIViewController) {
        let viewModel = WMFSlideshowViewModel(
            localizedStrings: localizedStrings,
            slides: slides(for: slideData),
            closeAction: { [weak self] in
                self?.instrument.submitInteraction(action: "click", elementId: "close")
                self?.finish(with: .dismissed)
            },
            primaryAction: { [weak self] in
                self?.instrument.submitInteraction(action: "click", elementId: "create_account")
                self?.finishAndCreateAccount()
            },
            secondaryAction: { [weak self] in
                self?.instrument.submitInteraction(action: "click", elementId: "maybe_later")
                self?.finish(with: .tappedMaybeLater)
            }
        )

        let viewController = WMFSlideshowViewController(viewModel: viewModel)
        let promptNavigationController = WMFComponentNavigationController(rootViewController: viewController, modalPresentationStyle: .fullScreen)

        // Full screen cannot be swiped away, so the close button is the only way out. The delegate
        // stays as a safety net for a dismissal from anywhere else.
        promptNavigationController.presentationController?.delegate = self
        self.promptNavigationController = promptNavigationController

        presenter.present(promptNavigationController, animated: true) { [weak self] in
            guard let self else { return }

            self.instrument.submitInteraction(action: "impression")

            guard !Self.alwaysShowForDesignReview else { return }
            Task { await self.dataController.recordImpression() }
        }
    }

    // MARK: - Outcomes

    private func finish(with outcome: WMFEvergreenAccountCreationDataController.PromptOutcome, completion: (() -> Void)? = nil) {
        guard !didRecordOutcome else {
            completion?()
            return
        }

        didRecordOutcome = true

        if !Self.alwaysShowForDesignReview {
            Task { await dataController.recordOutcome(outcome) }
        }

        guard let promptNavigationController else {
            completion?()
            return
        }

        promptNavigationController.dismiss(animated: true, completion: completion)
    }

    private func finishAndCreateAccount() {
        finish(with: .tappedCreateAccount) { [weak self] in
            self?.presentAccountCreation()
        }
    }

    private func presentAccountCreation() {
        let loginCoordinator = LoginCoordinator(
            navigationController: navigationController,
            theme: theme,
            loggingCategory: loggingCategory,
            startsOnAccountCreation: true
        )

        loginCoordinator.createAccountSuccessCustomDismissBlock = { [weak self] in
            self?.enableReadingListSyncAndDismissAccountCreation()
        }

        loginCoordinator.start()
    }

    /// Replaces the account creation screen's default dismissal, which asks "Turn on reading list
    /// syncing?" and turns it on by default
    private func enableReadingListSyncAndDismissAccountCreation() {
        dataStore.readingListsController.setSyncEnabled(true, shouldDeleteLocalLists: false, shouldDeleteRemoteLists: false)
        navigationController.presentedViewController?.dismiss(animated: true)
    }

    /// Carried through to the account creation form, which reports it as `invoke_source` on its own
    /// `impression` and `success` events. That is how an account created from this prompt is told
    /// apart from any other account created on that form.
    private var loggingCategory: EventCategoryMEP {
        return .encourage
    }

    // MARK: - Content

    private var localizedStrings: WMFSlideshowViewModel.LocalizedStrings {
        WMFSlideshowViewModel.LocalizedStrings(
            title: WMFLocalizedString(
                "evergreen-account-creation-title",
                value: "Wikipedia is better with an account",
                comment: "Title of the prompt inviting a logged out reader to create a Wikipedia account."
            ),
            primaryButtonTitle: WMFLocalizedString(
                "evergreen-account-creation-create-account-button",
                value: "Create account",
                comment: "Title of the button that starts account creation from the account creation prompt."
            ),
            secondaryButtonTitle: WMFLocalizedString(
                "evergreen-account-creation-maybe-later-button",
                value: "Maybe later",
                comment: "Title of the button that dismisses the account creation prompt for now."
            ),
            closeButtonAccessibilityLabel: CommonStrings.closeButtonAccessibilityLabel,
            slidePositionAccessibilityValue: { position, total in
                String.localizedStringWithFormat(
                    WMFLocalizedString(
                        "evergreen-account-creation-slide-position",
                        value: "%1$d of %2$d",
                        comment: "Accessibility value describing which of the account creation prompt's slides is showing. %1$d is replaced with the slide's position and %2$d with the number of slides."
                    ),
                    position,
                    total
                )
            }
        )
    }

    /// The reader's own numbers, with the copy falling back to a version without a number when they
    /// have no data of that kind.
    private func slides(for slideData: WMFEvergreenAccountCreationDataController.SlideData) -> [WMFSlideshowViewModel.Slide] {
        let yearInReviewTitle: String
        if let readingDayCount = slideData.readingDayCount {
            yearInReviewTitle = String.localizedStringWithFormat(
                WMFLocalizedString(
                    "evergreen-account-creation-year-in-review-title-count",
                    value: "See your {{PLURAL:%1$d|%1$d reading day|%1$d reading days}} come together in Year in Review",
                    comment: "Title of the Year in Review slide on the account creation prompt. %1$d is replaced with the number of days the reader has read an article on."
                ),
                readingDayCount
            )
        } else {
            yearInReviewTitle = WMFLocalizedString(
                "evergreen-account-creation-year-in-review-title",
                value: "See your reading days come together in Year in Review",
                comment: "Title of the Year in Review slide on the account creation prompt, for a reader with no reading history yet."
            )
        }

        let savedTitle: String
        if let savedArticleCount = slideData.savedArticleCount {
            savedTitle = String.localizedStringWithFormat(
                WMFLocalizedString(
                    "evergreen-account-creation-saved-title-count",
                    value: "Sync your {{PLURAL:%1$d|%1$d saved article|%1$d saved articles}}",
                    comment: "Title of the saved articles slide on the account creation prompt. %1$d is replaced with the number of articles the reader has saved."
                ),
                savedArticleCount
            )
        } else {
            savedTitle = WMFLocalizedString(
                "evergreen-account-creation-saved-title",
                value: "Sync your saved articles",
                comment: "Title of the saved articles slide on the account creation prompt, for a reader with nothing saved."
            )
        }

        let activityTitle: String
        if let articlesReadThisMonthCount = slideData.articlesReadThisMonthCount {
            activityTitle = String.localizedStringWithFormat(
                WMFLocalizedString(
                    "evergreen-account-creation-activity-title-count",
                    value: "Revisit your {{PLURAL:%1$d|%1$d recent read|%1$d recent reads}} with Activity",
                    comment: "Title of the Activity slide on the account creation prompt. %1$d is replaced with the number of articles the reader has read this month."
                ),
                articlesReadThisMonthCount
            )
        } else {
            activityTitle = WMFLocalizedString(
                "evergreen-account-creation-activity-title",
                value: "Revisit your recent reads with Activity",
                comment: "Title of the Activity slide on the account creation prompt, for a reader who has not read anything this month."
            )
        }

        return [
            WMFSlideshowViewModel.Slide(
                id: "year-in-review",
                illustration: .gif(name: "clock_2"),
                backgroundColor: WMFColor.yellow100,
                title: yearInReviewTitle,
                subtitle: WMFLocalizedString(
                    "evergreen-account-creation-year-in-review-body",
                    value: "Once a year, your reading days come back as a look at where the year took you, ready to share.",
                    comment: "Body of the Year in Review slide on the account creation prompt."
                )
            ),
            WMFSlideshowViewModel.Slide(
                id: "saved",
                illustration: .gif(name: "puzzle_2"),
                backgroundColor: WMFColor.green200,
                title: savedTitle,
                subtitle: WMFLocalizedString(
                    "evergreen-account-creation-saved-body",
                    value: "Log in to your Wikipedia account to allow your saved articles to be synced across devices.",
                    comment: "Body of the saved articles slide on the account creation prompt."
                )
            ),
            WMFSlideshowViewModel.Slide(
                id: "activity",
                illustration: .gif(name: "onboarding_puzzle"),
                backgroundColor: WMFColor.blue200,
                title: activityTitle,
                subtitle: WMFLocalizedString(
                    "evergreen-account-creation-activity-body",
                    value: "See your reading time, explored topics, and the reach of your contributions in the Activity tab.",
                    comment: "Body of the Activity slide on the account creation prompt."
                )
            ),
            WMFSlideshowViewModel.Slide(
                id: "edits",
                illustration: .asset(name: "puzzle_duo"),
                backgroundColor: WMFColor.lime200,
                title: WMFLocalizedString(
                    "evergreen-account-creation-edits-title",
                    value: "Get credit for your edits",
                    comment: "Title of the edits slide on the account creation prompt."
                ),
                subtitle: WMFLocalizedString(
                    "evergreen-account-creation-edits-body",
                    value: "Build a track record you can be proud of, with contributions across Wikimedia projects credited to your account.",
                    comment: "Body of the edits slide on the account creation prompt."
                )
            )
        ]
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate

extension EvergreenAccountCreationCoordinator: UIAdaptivePresentationControllerDelegate {

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        finish(with: .dismissed)
    }
}

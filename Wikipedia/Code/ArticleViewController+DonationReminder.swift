import WMF
import WMFData
import WMFComponents
import WMFNativeLocalizations

extension ArticleViewController {
    func showDonationReminderCardIfNeeded() {
        if let wrapUpCard = WMFDonationReminderDataController.shared.claimWrapUpCardImpression() {
            isShowingWrapUpCard = true
            switch wrapUpCard {
            case .feedbackSurvey:
                messagingController.injectDonationReminderCard(cardHTML: Self.wrapUpFeedbackCardHTML(theme: theme)) { _ in }
            case .recurringDonorPrompt(let pledgeAmount, let currencyCode):
                messagingController.injectDonationReminderCard(cardHTML: Self.wrapUpRecurringCardHTML(pledgeAmount: pledgeAmount, currencyCode: currencyCode, theme: theme)) { _ in }
            }
            return
        }

        Task {
            guard let reminder = try? await WMFDonationReminderDataController.shared.claimFollowUpReminderImpression(),
                  case .articlesRead(count: let articlesReadGoal) = reminder.trigger
            else { return }

            let configuration: DonationReminderCardConfiguration
            if reminder.goalReachedCount <= 1 {
                configuration = .firstMilestone(reminder: reminder, articlesReadGoal: articlesReadGoal)
            } else {
                configuration = .subsequentMilestone(reminder: reminder, articlesReadGoal: articlesReadGoal)
            }

            messagingController.injectDonationReminderCard(cardHTML: Self.donationReminderCardHTML(configuration: configuration)) { _ in }

            let source = DonateCoordinator.Source.donationReminderArticle(articleURL, pledgeAmount: reminder.amount, currencyCode: reminder.currencyCode)
            if let project = WikimediaProject(siteURL: self.articleURL),
               let metricsID = DonateCoordinator.metricsID(for: source, languageCode: articleURL.wmf_languageCode) {
                DonateFunnel.shared.logDonationReminderMilestoneImpression(project: project, metricsID: metricsID)
            }
        }
    }

    func removeDonationReminderCardIfNeeded() {
        let didCompleteDonationDuringFlow = isShowingDonateFlowFromDonationReminderCard && localDonationCount() > localDonationCountBeforeDonateFlow
        isShowingDonateFlowFromDonationReminderCard = false

        guard !isShowingWrapUpCard else {
            if didCompleteDonationDuringFlow {
                messagingController.removeDonationReminderCard()
                isShowingWrapUpCard = false
            }
            return
        }

        if WMFDonationReminderDataController.shared.isFollowUpReminderWindowClosed {
            messagingController.removeDonationReminderCard()
        }
    }

    private func localDonationCount() -> Int {
        WMFDonateDataController.shared.loadLocalDonationHistory(startDate: .distantPast, endDate: Date())?.count ?? 0
    }

    func removeDonationReminderCardAfterNavigationAway() {
        guard !isShowingDonateFlowFromDonationReminderCard else {
            return
        }
        messagingController.removeDonationReminderCard()
    }

    func handleDonationReminderLinkIfNeeded(href: String) -> Bool {
        if href.hasSuffix("#wmf-donation-reminder-donate") {
            didTapDonationReminderDonate()
            return true
        }

        if href.hasSuffix("#wmf-donation-reminder-not-now") {
            didTapDonationReminderNotNow()
            return true
        }

        if href.hasSuffix("#wmf-donation-reminder-share-feedback") {
            didTapWrapUpShareFeedback()
            return true
        }

        if href.hasSuffix("#wmf-donation-reminder-wrap-up-learn-more") {
            didTapWrapUpLearnMore()
            return true
        }

        if href.hasSuffix("#wmf-donation-reminder-wrap-up-no-thanks") {
            messagingController.removeDonationReminderCard()
            return true
        }

        if href.hasSuffix("#wmf-donation-reminder-give-monthly") {
            didTapWrapUpGiveMonthly()
            return true
        }

        return false
    }

    private func didTapDonationReminderDonate() {
        guard let reminder = WMFDonationReminderDataController.shared.loadReminder() else { return }
        let source = DonateCoordinator.Source.donationReminderArticle(articleURL, pledgeAmount: reminder.amount, currencyCode: reminder.currencyCode)

        if let project = WikimediaProject(siteURL: articleURL),
           let metricsID = DonateCoordinator.metricsID(for: source, languageCode: articleURL.wmf_languageCode) {
            DonateFunnel.shared.logDonationReminderMilestoneDidTapDonate(project: project, metricsID: metricsID)
        }

        startDonateFlowFromReminderCard(source: .donationReminderArticle(articleURL, pledgeAmount: reminder.amount, currencyCode: reminder.currencyCode))
    }

    private func didTapWrapUpGiveMonthly() {
        guard let reminder = WMFDonationReminderDataController.shared.loadReminder() else { return }

        startDonateFlowFromReminderCard(source: .donationReminderWrapUp(articleURL, pledgeAmount: reminder.amount, currencyCode: reminder.currencyCode))
    }

    private func startDonateFlowFromReminderCard(source: DonateCoordinator.Source) {
        messagingController.fetchDonationReminderDonateButtonRect { [weak self] buttonRect in
            guard let self, let navigationController else { return }

            let globalRect: CGRect
            if let buttonRect {
                globalRect = navigationController.view.convert(buttonRect, from: self.webView.scrollView)
            } else {
                globalRect = CGRect(x: navigationController.view.bounds.midX, y: navigationController.view.bounds.midY, width: 1, height: 1)
            }

            let donateCoordinator = DonateCoordinator(
                navigationController: navigationController,
                source: source,
                dataStore: self.dataStore,
                theme: self.theme,
                navigationStyle: .push,
                setLoadingBlock: { _ in },
                getDonateButtonGlobalRect: { globalRect }
            )
            self.donateCoordinator = donateCoordinator
            self.localDonationCountBeforeDonateFlow = self.localDonationCount()
            donateCoordinator.didCancelPaymentMethodPrompt = { [weak self] in
                self?.isShowingDonateFlowFromDonationReminderCard = false
            }
            self.isShowingDonateFlowFromDonationReminderCard = donateCoordinator.start()
        }
    }

    private func didTapDonationReminderNotNow() {
        
        guard let project = WikimediaProject(siteURL: articleURL) else { return }
        
        DonateFunnel.shared.logDonationReminderMilestoneDidTapNotNow(project: project)

        messagingController.removeDonationReminderCard()

        guard let reminder = WMFDonationReminderDataController.shared.loadReminder() else { return }

        WMFDonationReminderDataController.shared.closeFollowUpReminderWindow()

        let toastTitle = WMFLocalizedString("donation-reminder-card-not-now-toast-settings", value: "Donation reminders can be modified anytime in Settings.", comment: "Toast shown after the user dismisses the in-article donation reminder card.")
        let modifyButtonTitle = WMFLocalizedString("donation-reminder-card-not-now-toast-modify", value: "Modify", comment: "Title of the toast button that opens the donation reminder settings, shown after the user dismisses the in-article donation reminder card.")

        WMFToastManager.sharedInstance.showRichToast(toastTitle, buttonTitle: modifyButtonTitle, dismissPreviousToasts: true, buttonCallBack: { [weak self] in
            guard let self else { return }
            DonateFunnel.shared.logDonationReminderMilestoneDidTapNotNowToastSettings(project: project)
            self.showDonationReminderSettings(currencyCode: reminder.currencyCode, origin: .notNowToast(self.articleURL))
        })
    }

    private func showDonationReminderSettings(currencyCode: String, origin: WMFDonationReminderSetupViewModel.Origin) {
        guard let navigationController else { return }

        let coordinator = DonationReminderSetupCoordinator(navigationController: navigationController, currencyCode: currencyCode, theme: theme, origin: origin)
        donationReminderSetupCoordinator = coordinator
        coordinator.start()
    }

    private func didTapWrapUpShareFeedback() {
        let surveyIntro = WMFLocalizedString("donation-reminder-wrap-up-survey-intro", value: "A quick question about donation reminders", comment: "Introduction line of the feedback survey shown at the end of the donation reminder experiment.")
        let surveyQuestion = WMFLocalizedString("donation-reminder-wrap-up-survey-subtitle", value: "Should donation reminders based on articles you read become a permanent feature?", comment: "Question of the feedback survey shown at the end of the donation reminder experiment.")
        let surveyPlaceholder = WMFLocalizedString("donation-reminder-wrap-up-survey-placeholder", value: "Anything else? (Optional)", comment: "Placeholder of the optional free-form text field of the donation reminder feedback survey.")
        let surveyCharacterLimitError = WMFLocalizedString("donation-reminder-wrap-up-survey-character-limit", value: "Character limit exceeded", comment: "Error shown when the text in the free-form field of the donation reminder feedback survey passes the character limit.")
        let surveyOptionKeep = WMFLocalizedString("donation-reminder-wrap-up-survey-option-keep", value: "Keep it", comment: "Title of the donation reminder feedback survey option to keep the feature.")
        let surveyOptionRemove = WMFLocalizedString("donation-reminder-wrap-up-survey-option-remove", value: "Remove it", comment: "Title of the donation reminder feedback survey option to remove the feature.")

        let surveyLocalizedStrings = WMFSurveyViewModel.LocalizedStrings(
            title: CommonStrings.donationRemindersTitle,
            cancel: CommonStrings.cancelActionTitle,
            submit: CommonStrings.surveySubmitActionTitle,
            heading: surveyIntro,
            subtitle: surveyQuestion,
            instructions: nil,
            otherPlaceholder: surveyPlaceholder,
            characterLimitErrorText: surveyCharacterLimitError
        )

        let surveyOptions = [
            WMFSurveyViewModel.OptionViewModel(text: surveyOptionKeep, apiIdentifer: "keep"),
            WMFSurveyViewModel.OptionViewModel(text: surveyOptionRemove, apiIdentifer: "remove"),
            WMFSurveyViewModel.OptionViewModel(text: CommonStrings.notSureButtonTitle, apiIdentifer: "notsure")
        ]

        let surveyView = WMFSurveyView(viewModel: WMFSurveyViewModel(localizedStrings: surveyLocalizedStrings, options: surveyOptions, selectionType: .single, shouldShowMultilineText: true, otherTextCharacterLimit: 250), cancelAction: { [weak self] in
            self?.presentedViewController?.dismiss(animated: true)
        }, submitAction: { [weak self] _, _ in
            self?.presentedViewController?.dismiss(animated: true, completion: {
                self?.messagingController.removeDonationReminderCard()
                let toastTitle = WMFLocalizedString("donation-reminder-wrap-up-survey-toast", value: "Thanks for your feedback. Your answer helps us decide what to build next.", comment: "Toast shown after the user submits the donation reminder feedback survey.")
                WMFToastManager.sharedInstance.showRichToast(toastTitle, dismissPreviousToasts: true)
            })
        })

        let hostingController = WMFComponentHostingController(rootView: surveyView)
        present(hostingController, animated: true)
    }

    private func didTapWrapUpLearnMore() {
        guard let appLanguage = WMFDataEnvironment.current.primaryAppLanguage,
              let url = WMFProject.mediawiki.translatedHelpURL(pathComponents: ["Wikimedia Apps", "Team", "Android", "Customizable Donation Reminder Experiment"], section: "Experiment #2", language: appLanguage)
        else {
            return
        }

        let config = SinglePageWebViewController.StandardConfig(url: url, useSimpleNavigationBar: true)
        let webViewController = SinglePageWebViewController(configType: .standard(config), theme: theme)
        let webNavigationController = WMFComponentNavigationController(rootViewController: webViewController, modalPresentationStyle: .pageSheet)
        present(webNavigationController, animated: true)
    }

    private static func wrapUpFeedbackCardHTML(theme: Theme) -> String {
        let heading = WMFLocalizedString("donation-reminder-wrap-up-card-heading", value: "That’s a wrap on donation reminders", comment: "Heading of the in-article card shown at the end of the donation reminder experiment.")
        let body = WMFLocalizedString("donation-reminder-wrap-up-card-body", value: "Thanks for testing donation reminders based on the articles you read. Your feedback decides if this becomes a permanent way to give on Wikipedia. It only takes a minute, and no donation is required.", comment: "Body of the in-article card shown at the end of the donation reminder experiment.")
        let shareFeedbackTitle = WMFLocalizedString("donation-reminder-wrap-up-card-share-feedback", value: "Share feedback", comment: "Title of the button that opens the feedback survey, on the in-article card shown at the end of the donation reminder experiment.")

        return wrapUpCardHTML(heading: heading, body: body, primaryActionAnchor: "wmf-donation-reminder-share-feedback", primaryActionTitle: shareFeedbackTitle, theme: theme)
    }

    private static func wrapUpRecurringCardHTML(pledgeAmount: Decimal, currencyCode: String, theme: Theme) -> String {
        let amountFormatter = NumberFormatter.wmfCurrencyFormatter
        amountFormatter.currencyCode = currencyCode
        let formattedPledgeAmount = amountFormatter.string(from: pledgeAmount as NSNumber) ?? "\(pledgeAmount)"

        let heading = WMFLocalizedString("donation-reminder-wrap-up-recurring-card-heading", value: "This is the end of the experiment", comment: "Heading of the in-article card that asks the user to start a monthly donation, shown at the end of the donation reminder experiment.")
        let bodyFormat = WMFLocalizedString("donation-reminder-wrap-up-recurring-card-body", value: "We will no longer show in-app reminders but you can still support by donating your pledged amount %1$@ monthly.", comment: "Body of the in-article card that asks the user to start a monthly donation, shown at the end of the donation reminder experiment. %1$@ is the pledged donation amount.")
        let body = String.localizedStringWithFormat(bodyFormat, formattedPledgeAmount)
        let giveMonthlyTitle = WMFLocalizedString("donation-reminder-wrap-up-recurring-card-give-monthly", value: "Give monthly", comment: "Title of the button that opens the payment flow with a monthly recurring donation preselected, on the in-article card shown at the end of the donation reminder experiment.")

        return wrapUpCardHTML(heading: heading, body: body, primaryActionAnchor: "wmf-donation-reminder-give-monthly", primaryActionTitle: giveMonthlyTitle, theme: theme)
    }

    private static func inlineIconHTML(image: UIImage?, tintColor: UIColor) -> String {
        guard let image else {
            return ""
        }

        let renderer = UIGraphicsImageRenderer(size: image.size)
        let tintedImage = renderer.image { _ in
            image.withTintColor(tintColor).draw(in: CGRect(origin: .zero, size: image.size))
        }

        guard let pngData = tintedImage.pngData() else {
            return ""
        }

        let width = Int(image.size.width.rounded())
        let height = Int(image.size.height.rounded())
        return "<img src='data:image/png;base64,\(pngData.base64EncodedString())' width='\(width)' height='\(height)' aria-hidden='true'/>"
    }

    private static func wrapUpCardHTML(heading: String, body: String, primaryActionAnchor: String, primaryActionTitle: String, theme: Theme) -> String {
        let betaPillText = CommonStrings.betaLabel
        let learnMoreText = CommonStrings.learnMoreTitle()
        let noThanksTitle = CommonStrings.noThanksTitle

        let flaskIconHTML = inlineIconHTML(image: WMFSFSymbolIcon.for(symbol: .flask, font: WMFFont.caption1), tintColor: theme.colors.primaryText)
        let externalLinkIconHTML = "<svg width='12' height='12' viewBox='0 0 24 24' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round' aria-hidden='true'><path d='M15 3h6v6'/><path d='M10 14 21 3'/><path d='M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6'/></svg>"

        return """
            <div id='wmf-donation-reminder-card-container'>
                <div id='wmf-donation-reminder-card'>
                    <div class='wmf-donation-reminder-card-top-row'>
                        <span class='wmf-donation-reminder-card-beta-pill'>\(flaskIconHTML)\(betaPillText.donationReminderHTMLEscaped)</span>
                        <a class='wmf-donation-reminder-card-learn-more' href='#wmf-donation-reminder-wrap-up-learn-more'>\(learnMoreText.donationReminderHTMLEscaped)\(externalLinkIconHTML)</a>
                    </div>
                    <p class='wmf-donation-reminder-card-heading'>\(heading.donationReminderHTMLEscaped)</p>
                    <p class='wmf-donation-reminder-card-body'>\(body.donationReminderHTMLEscaped)</p>
                    <div class='wmf-donation-reminder-card-actions'>
                        <a class='wmf-donation-reminder-card-donate' href='#\(primaryActionAnchor)'>\(primaryActionTitle.donationReminderHTMLEscaped)</a>
                        <a class='wmf-donation-reminder-card-not-now' href='#wmf-donation-reminder-wrap-up-no-thanks'>\(noThanksTitle.donationReminderHTMLEscaped)</a>
                    </div>
                </div>
            </div>
        """
    }

    private static func donationReminderCardHTML(configuration: DonationReminderCardConfiguration) -> String {
        return """
            <div id='wmf-donation-reminder-card-container'>
                <div id='wmf-donation-reminder-card'>
                    <p class='wmf-donation-reminder-card-heading'>\(configuration.heading.donationReminderHTMLEscaped)</p>
                    <p class='wmf-donation-reminder-card-body'>\(configuration.body.donationReminderHTMLEscaped)</p>
                    <div class='wmf-donation-reminder-card-actions'>
                        <a class='wmf-donation-reminder-card-donate' href='#wmf-donation-reminder-donate'>\(configuration.primaryActionTitle.donationReminderHTMLEscaped)</a>
                        <a class='wmf-donation-reminder-card-not-now' href='#wmf-donation-reminder-not-now'>\(configuration.secondaryActionTitle.donationReminderHTMLEscaped)</a>
                    </div>
                </div>
            </div>
        """
    }
}

private struct DonationReminderCardConfiguration {
    let heading: String
    let body: String
    let primaryActionTitle: String
    let secondaryActionTitle: String

    static func firstMilestone(reminder: WMFDonationReminder, articlesReadGoal: Int) -> DonationReminderCardConfiguration {
        let amountString = pledgeAmountString(reminder: reminder)
        let headingFormat = WMFLocalizedString("donation-reminder-card-heading", value: "You’ve read {{PLURAL:%1$d|%1$d article|%1$d articles}} since you pledged %2$@!", comment: "Heading of the in-article donation reminder card the first time the user reaches their reading goal. %1$d is the number of articles read, %2$@ is the pledged donation amount.")
        let heading = String.localizedStringWithFormat(headingFormat, articlesReadGoal, amountString)

        return DonationReminderCardConfiguration(heading: heading, body: body(reminder: reminder, articlesReadGoal: articlesReadGoal), primaryActionTitle: donateTitle, secondaryActionTitle: notNowTitle)
    }

    static func subsequentMilestone(reminder: WMFDonationReminder, articlesReadGoal: Int) -> DonationReminderCardConfiguration {
        let headingFormat = WMFLocalizedString("donation-reminder-card-subsequent-heading", value: "You’ve read another {{PLURAL:%1$d|%1$d article|%1$d articles}}!", comment: "Heading of the in-article donation reminder card when the user reaches their reading goal again. %1$d is the number of articles read.")
        let heading = String.localizedStringWithFormat(headingFormat, articlesReadGoal)

        return DonationReminderCardConfiguration(heading: heading, body: body(reminder: reminder, articlesReadGoal: articlesReadGoal), primaryActionTitle: donateTitle, secondaryActionTitle: notNowTitle)
    }

    private static func body(reminder: WMFDonationReminder, articlesReadGoal: Int) -> String {
        let dateString = DateFormatter.localizedString(from: reminder.createdDate, dateStyle: .long, timeStyle: .none)
        let bodyFormat = WMFLocalizedString("donation-reminder-card-body", value: "On %1$@, you asked us to remind you to donate after reading {{PLURAL:%2$d|%2$d article|%2$d articles}}. If Wikipedia has provided you with %3$@ of knowledge, please join the 2%% of readers who give and complete your pledge today.", comment: "Body of the in-article donation reminder card. %1$@ is the date the user set up the reminder, %2$d is the number of articles read, %3$@ is the pledged donation amount.")
        return String.localizedStringWithFormat(bodyFormat, dateString, articlesReadGoal, pledgeAmountString(reminder: reminder))
    }

    private static var donateTitle: String {
        WMFLocalizedString("donation-reminder-card-donate", value: "Yes, donate now", comment: "Title of the donate button on the in-article donation reminder card.")
    }

    private static var notNowTitle: String {
        WMFLocalizedString("donation-reminder-card-not-now", value: "Not now", comment: "Title of the dismiss link on the in-article donation reminder card.")
    }

    private static func pledgeAmountString(reminder: WMFDonationReminder) -> String {
        let amountFormatter = NumberFormatter.wmfCurrencyFormatter
        amountFormatter.currencyCode = reminder.currencyCode
        return amountFormatter.string(from: reminder.amount as NSNumber) ?? "\(reminder.amount)"
    }
}

private extension String {
    var donationReminderHTMLEscaped: String {
        self
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }
}

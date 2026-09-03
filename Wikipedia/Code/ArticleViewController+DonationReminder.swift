import WMF
import WMFData
import WMFComponents
import WMFNativeLocalizations

extension ArticleViewController {
    func showDonationReminderCardIfNeeded() {
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
        }
    }

    func removeDonationReminderCardIfNeeded() {
        isShowingDonateFlowFromDonationReminderCard = false

        if !WMFDeveloperSettingsDataController.shared.enableDonationReminder || WMFDonationReminderDataController.shared.isFollowUpReminderWindowClosed {
            messagingController.removeDonationReminderCard()
        }
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

        return false
    }

    private func didTapDonationReminderDonate() {
        guard let reminder = WMFDonationReminderDataController.shared.loadReminder() else { return }

        messagingController.fetchDonationReminderDonateButtonRect { [weak self] buttonRect in
            guard let self, let navigationController else { return }

            let globalRect: CGRect
            if let buttonRect {
                globalRect = navigationController.view.convert(buttonRect, from: self.webView.scrollView)
            } else {
                globalRect = CGRect(x: navigationController.view.bounds.midX, y: navigationController.view.bounds.midY, width: 1, height: 1)
            }

            let donateCoordinator = DonateCoordinator(navigationController: navigationController, source: .donationReminderArticle(self.articleURL, pledgeAmount: reminder.amount, currencyCode: reminder.currencyCode), dataStore: self.dataStore, theme: self.theme, navigationStyle: .push, setLoadingBlock: { _ in }, getDonateButtonGlobalRect: { globalRect })
            self.donateCoordinator = donateCoordinator
            donateCoordinator.didCancelPaymentMethodPrompt = { [weak self] in
                self?.isShowingDonateFlowFromDonationReminderCard = false
            }
            self.isShowingDonateFlowFromDonationReminderCard = donateCoordinator.start()
        }
    }

    private func didTapDonationReminderNotNow() {
        messagingController.removeDonationReminderCard()

        guard let reminder = WMFDonationReminderDataController.shared.loadReminder() else { return }

        WMFDonationReminderDataController.shared.closeFollowUpReminderWindow()

        let toastTitle = WMFLocalizedString("donation-reminder-card-not-now-toast-settings", value: "Donation reminders can be modified anytime in Settings.", comment: "Toast shown after the user dismisses the in-article donation reminder card.")
        let modifyButtonTitle = WMFLocalizedString("donation-reminder-card-not-now-toast-modify", value: "Modify", comment: "Title of the toast button that opens the donation reminder settings, shown after the user dismisses the in-article donation reminder card.")

        WMFToastManager.sharedInstance.showRichToast(toastTitle, buttonTitle: modifyButtonTitle, dismissPreviousToasts: true, buttonCallBack: { [weak self] in
            self?.showDonationReminderSettings(currencyCode: reminder.currencyCode)
        })
    }

    private func showDonationReminderSettings(currencyCode: String) {
        guard let navigationController else { return }

        let coordinator = DonationReminderSetupCoordinator(navigationController: navigationController, currencyCode: currencyCode, theme: theme, origin: .settings)
        donationReminderSetupCoordinator = coordinator
        coordinator.start()
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

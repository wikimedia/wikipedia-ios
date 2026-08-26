import UIKit
import WMF
import WMFComponents
import WMFData
import WMFNativeLocalizations

final class DonationReminderSetupCoordinator: Coordinator {

    let navigationController: UINavigationController
    private let currencyCode: String
    private let theme: Theme
    private let origin: WMFDonationReminderSetupViewModel.Origin
    private let experimentEndDate: Date?

    init(
        navigationController: UINavigationController,
        currencyCode: String,
        theme: Theme,
        origin: WMFDonationReminderSetupViewModel.Origin,
        experimentEndDate: Date? = nil
    ) {
        self.navigationController = navigationController
        self.currencyCode = currencyCode
        self.theme = theme
        self.origin = origin
        self.experimentEndDate = experimentEndDate
    }

    @discardableResult
    func start() -> Bool {
        let minimumAmount = WMFDonateDataController.shared.loadConfigs().donateConfig?.currencyMinimumDonation[currencyCode] ?? 1
        let configuration = WMFDonationReminderSetupViewModel.experimentConfiguration(currencyCode: currencyCode, minimumAmount: minimumAmount)
        let viewModel = WMFDonationReminderSetupViewModel(configuration: configuration, origin: origin, experimentEndDate: experimentEndDate)

        viewModel.didConfirmReminder = { [weak self] _ in
            self?.navigationController.popViewController(animated: true)
        }

        viewModel.didTapNoThanks = { [weak self] in
            self?.navigationController.popViewController(animated: true)
        }

        viewModel.didTapAboutExperiment = { [weak self] in
            self?.showAboutExperiment()
        }

        viewModel.didTapReportProblem = { [weak self] in
            self?.showReportProblem()
        }

        let viewController = WMFDonationReminderSetupViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
        return true
    }

    private func showAboutExperiment() {
        guard let appLanguage = WMFDataEnvironment.current.primaryAppLanguage,
              let url = WMFProject.mediawiki.translatedHelpURL(pathComponents: ["Wikimedia Apps", "Team", "Android", "Customizable Donation Reminder Experiment"], section: "Experiment #2", language: appLanguage)
        else {
            return
        }
        let config = SinglePageWebViewController.StandardConfig(url: url, useSimpleNavigationBar: true)
        let webViewController = SinglePageWebViewController(configType: .standard(config), theme: theme)
        let webNavigationController = WMFComponentNavigationController(rootViewController: webViewController, modalPresentationStyle: .fullScreen)
        navigationController.present(webNavigationController, animated: true)
    }

    private func showReportProblem() {
        let emailAddress = "ios-support@wikimedia.org"
        let emailSubject = WMFLocalizedString("donation-reminder-email-report-subject", value: "Issue Report - Donation Reminders", comment: "Subject of the pre-filled issue report email for the donation reminders feature.")
        let emailBodyFirstLine = WMFLocalizedString("donation-reminder-email-report-body", value: "I have encountered a problem with the donation reminders feature:", comment: "First line of the pre-filled issue report email body for the donation reminders feature.")
        let emailBody = [
            emailBodyFirstLine,
            CommonStrings.issueReportEmailBodyDescribeProblem,
            CommonStrings.issueReportEmailBodyBehavior,
            CommonStrings.issueReportEmailBodyProposedSolution,
            CommonStrings.issueReportEmailBodyScreenshotsOrLinks
        ].joined(separator: "\n\n")
        let mailto = "mailto:\(emailAddress)?subject=\(emailSubject)&body=\(emailBody)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)

        guard let mailto,
              let mailtoURL = URL(string: mailto),
              UIApplication.shared.canOpenURL(mailtoURL)
        else {
            WMFToastManager.sharedInstance.showToast(CommonStrings.noEmailClient, sticky: false, dismissPreviousToasts: false)
            return
        }
        UIApplication.shared.open(mailtoURL)
    }
}

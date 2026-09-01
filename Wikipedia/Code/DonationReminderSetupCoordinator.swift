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
    private let metricsID: String?
    private let project: WikimediaProject?

    init(
        navigationController: UINavigationController,
        currencyCode: String,
        theme: Theme,
        origin: WMFDonationReminderSetupViewModel.Origin,
        metricsID: String? = nil,
        project: WikimediaProject? = nil
    ) {
        self.navigationController = navigationController
        self.currencyCode = currencyCode
        self.theme = theme
        self.origin = origin
        self.metricsID = metricsID
        self.project = project
    }

    @discardableResult
    func start() -> Bool {
        let donateConfig = WMFDonateDataController.shared.loadConfigs().donateConfig
        let minimumAmount = donateConfig?.currencyMinimumDonation[currencyCode] ?? 1
        var maximumAmount = donateConfig?.getMaxAmount(for: currencyCode)
        if maximumAmount?.isZero == true {
            maximumAmount = nil
        }
        let configuration = WMFDonationReminderSetupViewModel.experimentConfiguration(currencyCode: currencyCode, minimumAmount: minimumAmount, maximumAmount: maximumAmount)
        let viewModel = WMFDonationReminderSetupViewModel(configuration: configuration, origin: origin)
        
        let project = self.project ?? resolvedProject()
        let metricsID = self.metricsID ?? resolvedMetricsID()

        viewModel.logSetupFormDidAppear = {
            guard let project, let metricsID else { return }
            DonateFunnel.shared.logDonationReminderSetupFormDidAppear(project: project, metricsID: metricsID)
        }

        viewModel.logDidTapLearnMore = {
            guard let project else { return }
            DonateFunnel.shared.logDonationReminderDidTapLearnMore(project: project)
        }

        viewModel.logDidTapReportProblem = {
            guard let project else { return }
            DonateFunnel.shared.logDonationReminderDidTapReportProblem(project: project)
        }

        viewModel.logDidTapConfirm = { milestoneDefault, readFreq, donateAmount in
            guard let project else { return }
            DonateFunnel.shared.logDonationReminderDidTapConfirm(project: project, milestoneDefault: milestoneDefault, readFreq: readFreq, donateAmount: donateAmount)
        }

        viewModel.logDidTapNoThanks = {
            guard let project else { return }
            DonateFunnel.shared.logDonationReminderDidTapNoThanks(project: project)
        }

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

    private func resolvedProject() -> WikimediaProject? {
        guard let appLanguage = WMFDataEnvironment.current.primaryAppLanguage else { return nil }
        return WikimediaProject(wmfProject: .wikipedia(appLanguage))
    }

    private func resolvedMetricsID() -> String? {
        guard let assignment = WMFDonationReminderDataController.shared.experimentAssignment,
              let countryCode = Locale.current.region?.identifier,
              let appLanguage = WMFDataEnvironment.current.primaryAppLanguage else { return nil }
        let suffix: String
        switch assignment {
        case .control: suffix = "remindA"
        case .groupB: suffix = "remindB"
        case .groupC: suffix = "remindC"
        }
        return "\(appLanguage.languageCode)\(countryCode)_\(WMFDonationReminderDataController.experimentCampaignID)_\(suffix)_iOS"
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

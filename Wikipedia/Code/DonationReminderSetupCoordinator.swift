import UIKit
import WMFComponents
import WMFData

final class DonationReminderSetupCoordinator: Coordinator {

    let navigationController: UINavigationController
    private let currencyCode: String
    private let theme: Theme

    init(navigationController: UINavigationController, currencyCode: String, theme: Theme) {
        self.navigationController = navigationController
        self.currencyCode = currencyCode
        self.theme = theme
    }

    @discardableResult
    func start() -> Bool {
        let minimumAmount = WMFDonateDataController.shared.loadConfigs().donateConfig?.currencyMinimumDonation[currencyCode] ?? 1
        let configuration = WMFDonationReminderSetupViewModel.experimentConfiguration(currencyCode: currencyCode, minimumAmount: minimumAmount)
        let viewModel = WMFDonationReminderSetupViewModel(configuration: configuration)

        viewModel.didConfirmReminder = { [weak self] _ in
            self?.navigationController.popViewController(animated: true)
        }

        viewModel.didTapAboutExperiment = { [weak self] in
            self?.showAboutExperiment()
        }

        let viewController = WMFDonationReminderSetupViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
        return true
    }

    private func showAboutExperiment() {
        guard let url = URL(string: "https://www.mediawiki.org/wiki/Wikimedia_Apps/Team/Android/Customizable_Donation_Reminder_Experiment#Experiment_%232") else {
            return
        }
        let config = SinglePageWebViewController.StandardConfig(url: url, useSimpleNavigationBar: true)
        let webViewController = SinglePageWebViewController(configType: .standard(config), theme: theme)
        let webNavigationController = WMFComponentNavigationController(rootViewController: webViewController, modalPresentationStyle: .fullScreen)
        navigationController.present(webNavigationController, animated: true)
    }
}

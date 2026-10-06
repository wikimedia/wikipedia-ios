import UIKit
import WMFComponents
import WMFData

/// Presents the sheet that explains searching within articles.
final class SemanticSearchInfoCoordinator: Coordinator {

    let navigationController: UINavigationController

    private let languageCode: String

    /// The project page of the experiment, in the search language when a translation exists.
    private var learnMoreURL: URL? {
        WMFProject.mediawiki.translatedHelpURL(
            pathComponents: ["Readers", "Information Retrieval", "Phase 2"],
            section: nil,
            language: WMFLanguage(languageCode: languageCode, languageVariantCode: nil))
    }

    private weak var sheetNavigationController: UINavigationController?

    init(navigationController: UINavigationController, languageCode: String) {
        self.navigationController = navigationController
        self.languageCode = languageCode
    }

    @discardableResult
    func start() -> Bool {
        let viewModel = WMFSemanticSearchInfoViewModel(
            languageCode: languageCode,
            learnMoreAction: { [weak self] in
                guard let self, let learnMoreURL else { return }
                navigationController.navigate(to: learnMoreURL, useSafari: true)
            },
            closeAction: { [weak self] in
                self?.sheetNavigationController?.dismiss(animated: true)
            }
        )

        let hostingController = WMFSemanticSearchInfoHostingController(viewModel: viewModel)
        let sheetNavigationController = WMFComponentNavigationController(
            rootViewController: hostingController,
            modalPresentationStyle: .pageSheet
        )

        self.sheetNavigationController = sheetNavigationController

        let presenter = navigationController.presentedViewController ?? navigationController
        presenter.view.endEditing(true)
        presenter.present(sheetNavigationController, animated: true)
        return true
    }
}

import UIKit
import WMFComponents
import WMFData

/// Presents the sheet that explains searching within articles.
final class SemanticSearchInfoCoordinator: Coordinator {

    let navigationController: UINavigationController

    private let languageCode: String
    private let instrumentation: SearchInstrumentation

    /// The project page of the experiment, in the search language when a translation exists.
    private var learnMoreURL: URL? {
        WMFProject.mediawiki.translatedHelpURL(
            pathComponents: ["Readers", "Information Retrieval", "Phase 2"],
            section: nil,
            language: WMFLanguage(languageCode: languageCode, languageVariantCode: nil))
    }

    private weak var sheetNavigationController: UINavigationController?

    init(navigationController: UINavigationController, languageCode: String, instrumentation: SearchInstrumentation) {
        self.navigationController = navigationController
        self.languageCode = languageCode
        self.instrumentation = instrumentation
    }

    @discardableResult
    func start() -> Bool {
        let viewModel = WMFSemanticSearchInfoViewModel(
            languageCode: languageCode,
            learnMoreAction: { [weak self] in
                guard let self, let learnMoreURL = self.learnMoreURL else { return }
                self.instrumentation.logInfoLearnMore()
                self.navigationController.navigate(to: learnMoreURL, useSafari: true)
            },
            closeAction: { [weak self] in
                guard let self else { return }
                self.instrumentation.logInfoClose()
                self.sheetNavigationController?.dismiss(animated: true)
            }
        )
        instrumentation.logInfoImpression()

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

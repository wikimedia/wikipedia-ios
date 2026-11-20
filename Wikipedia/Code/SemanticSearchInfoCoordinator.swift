import UIKit
import WMFComponents
import WMFData

/// Presents the sheet that explains searching within articles.
final class SemanticSearchInfoCoordinator: Coordinator {

    let navigationController: UINavigationController

    private let languageCode: String
    private let instrumentation: SearchInstrumentation
    /// The sheet of the interleaved list does not send the events of the semantic search sheet.
    private let kind: WMFSemanticSearchInfoViewModel.Kind

    /// The project page of the experiment, in the search language when a translation exists.
    private var learnMoreURL: URL? {
        WMFProject.mediawiki.translatedHelpURL(
            pathComponents: ["Readers", "Information Retrieval", "Phase 2"],
            section: nil,
            language: WMFLanguage(languageCode: languageCode, languageVariantCode: nil))
    }

    private weak var sheetNavigationController: UINavigationController?

    init(
        navigationController: UINavigationController,
        languageCode: String,
        instrumentation: SearchInstrumentation,
        kind: WMFSemanticSearchInfoViewModel.Kind = .semanticSearchSheet
    ) {
        self.navigationController = navigationController
        self.languageCode = languageCode
        self.instrumentation = instrumentation
        self.kind = kind
    }

    private var logsSemanticSearchSheetEvents: Bool {
        switch kind {
        case .semanticSearchSheet:
            true
        case .interleavedResults:
            false
        }
    }

    @discardableResult
    func start() -> Bool {
        // TODO(EF-3): The interleaved list logs the opening of the sheet with the events of T441663.
        let sheetKind: WMFSemanticSearchInfoViewModel.Kind
        switch kind {
        case .interleavedResults(let turnOffAction?):
            // The sheet closes before the action opens another screen.
            sheetKind = .interleavedResults(turnOffAction: { [weak self] in
                self?.sheetNavigationController?.dismiss(animated: true) {
                    turnOffAction()
                }
            })
        case .semanticSearchSheet, .interleavedResults(nil):
            sheetKind = kind
        }
        let viewModel = WMFSemanticSearchInfoViewModel(
            languageCode: languageCode,
            kind: sheetKind,
            learnMoreAction: { [weak self] in
                guard let self, let learnMoreURL = self.learnMoreURL else { return }
                if self.logsSemanticSearchSheetEvents {
                    self.instrumentation.logInfoLearnMore()
                }
                self.navigationController.navigate(to: learnMoreURL, useSafari: true)
            },
            closeAction: { [weak self] in
                guard let self else { return }
                if self.logsSemanticSearchSheetEvents {
                    self.instrumentation.logInfoClose()
                }
                self.sheetNavigationController?.dismiss(animated: true)
            }
        )
        if logsSemanticSearchSheetEvents {
            instrumentation.logInfoImpression()
        }

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

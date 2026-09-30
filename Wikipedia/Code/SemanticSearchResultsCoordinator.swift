import UIKit
import WMFComponents
import WMFData

/// Presents the sheet of passages found inside articles for a search query.
final class SemanticSearchResultsCoordinator: NSObject, Coordinator {

    let navigationController: UINavigationController

    private let query: String
    private let project: WMFProject
    private let didSelectResult: (WMFSemanticSearchResult) -> Void

    private var viewModel: WMFSemanticSearchResultsViewModel?
    /// Kept after the sheet is dismissed to open an article, so `restore()` can show the same sheet again.
    private var sheetNavigationController: UINavigationController?
    private var selectedDetentIdentifier: UISheetPresentationController.Detent.Identifier?

    init(
        navigationController: UINavigationController,
        query: String,
        project: WMFProject,
        didSelectResult: @escaping (WMFSemanticSearchResult) -> Void
    ) {
        self.navigationController = navigationController
        self.query = query
        self.project = project
        self.didSelectResult = didSelectResult
    }

    @discardableResult
    func start() -> Bool {
        let viewModel = WMFSemanticSearchResultsViewModel(
            query: query,
            project: project,
            readInArticleAction: { [weak self] result in
                self?.open(result)
            },
            closeAction: { [weak self] in
                self?.dismiss()
            },
            feedbackAction: { _, _ in
                // TODO: Send the rating and optional text the reader submits.
            },
            feedbackTextFieldFocusAction: { [weak self] in
                self?.expandSheet()
            }
        )

        let hostingController = WMFSemanticSearchResultsHostingController(viewModel: viewModel)
        let sheetNavigationController = WMFComponentNavigationController(
            rootViewController: hostingController,
            modalPresentationStyle: .pageSheet
        )

        self.viewModel = viewModel
        self.sheetNavigationController = sheetNavigationController

        viewModel.load()
        present(sheetNavigationController)
        return true
    }

    /// Presents the sheet again as the reader left it before opening an article from it.
    func restore() {
        guard let sheetNavigationController, sheetNavigationController.presentingViewController == nil else { return }

        present(sheetNavigationController)
    }

    private func present(_ sheetNavigationController: UINavigationController) {
        // Each presentation gets a new sheet presentation controller, so configure it every time.
        if let sheet = sheetNavigationController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.selectedDetentIdentifier = selectedDetentIdentifier
            sheet.prefersGrabberVisible = true
            sheet.delegate = self
        }

        let presenter = navigationController.presentedViewController ?? navigationController
        presenter.view.endEditing(true)
        presenter.present(sheetNavigationController, animated: true)
    }

    private func open(_ result: WMFSemanticSearchResult) {
        viewModel?.cancel()
        selectedDetentIdentifier = sheetNavigationController?.sheetPresentationController?.selectedDetentIdentifier
        sheetNavigationController?.dismiss(animated: true) { [weak self] in
            self?.didSelectResult(result)
        }
    }

    /// At the medium detent the keyboard leaves little room to type and scroll.
    private func expandSheet() {
        guard let sheet = sheetNavigationController?.sheetPresentationController,
              sheet.selectedDetentIdentifier != .large else { return }

        sheet.animateChanges {
            sheet.selectedDetentIdentifier = .large
        }
    }

    private func dismiss() {
        viewModel?.cancel()
        sheetNavigationController?.dismiss(animated: true)
        sheetNavigationController = nil
    }
}

extension SemanticSearchResultsCoordinator: UISheetPresentationControllerDelegate {

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        viewModel?.cancel()
        sheetNavigationController = nil
    }

}

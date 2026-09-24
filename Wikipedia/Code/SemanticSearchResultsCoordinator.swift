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
    private weak var sheetNavigationController: UINavigationController?

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
            }
        )

        let hostingController = WMFSemanticSearchResultsHostingController(viewModel: viewModel)
        let sheetNavigationController = WMFComponentNavigationController(
            rootViewController: hostingController,
            modalPresentationStyle: .pageSheet
        )

        if let sheet = sheetNavigationController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.delegate = self
        }

        self.viewModel = viewModel
        self.sheetNavigationController = sheetNavigationController

        viewModel.load()
        let presenter = navigationController.presentedViewController ?? navigationController
        presenter.view.endEditing(true)
        presenter.present(sheetNavigationController, animated: true)
        return true
    }

    private func open(_ result: WMFSemanticSearchResult) {
        viewModel?.cancel()
        sheetNavigationController?.dismiss(animated: true) { [weak self] in
            self?.didSelectResult(result)
        }
    }

    private func dismiss() {
        viewModel?.cancel()
        sheetNavigationController?.dismiss(animated: true)
    }
}

extension SemanticSearchResultsCoordinator: UISheetPresentationControllerDelegate {

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        viewModel?.cancel()
    }

}

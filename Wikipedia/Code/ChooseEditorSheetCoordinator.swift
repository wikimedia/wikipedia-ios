import UIKit
import SwiftUI
import WMFComponents
import WMFNativeLocalizations

final class ChooseEditorSheetCoordinator: Coordinator {

    var navigationController: UINavigationController
    private let theme: Theme
    private let didChoose: (WMFChooseEditorViewModel.EditMode, _ dontShowAgain: Bool) -> Void

    private weak var sheetNavigationController: WMFComponentNavigationController?

    init(navigationController: UINavigationController, theme: Theme, didChoose: @escaping (WMFChooseEditorViewModel.EditMode, Bool) -> Void) {
        self.navigationController = navigationController
        self.theme = theme
        self.didChoose = didChoose
    }

    @discardableResult
    func start() -> Bool {
        let viewModel = WMFChooseEditorViewModel(
            didTapContinue: { mode, dontShowAgain in
                self.sheetNavigationController?.dismiss(animated: true) {
                    self.didChoose(mode, dontShowAgain)
                }
            },
            didTapClose: {
                self.sheetNavigationController?.dismiss(animated: true)
            }
        )

        let view = WMFChooseEditorView(viewModel: viewModel)
        let sizingController = UIHostingController(rootView: view.mainContent)

        let traitCollection = navigationController.traitCollection
        let isPadRegularWidth = navigationController.traitCollection.userInterfaceIdiom == .pad && traitCollection.horizontalSizeClass == .regular

        let fullWidth = navigationController.view.bounds.width
        let sheetWidth: CGFloat = fullWidth * (isPadRegularWidth ? 0.6 : 1)
        let contentHeight = sizingController.sizeThatFits(in: CGSize(width: sheetWidth, height: .greatestFiniteMagnitude)).height

        let viewController = WMFChooseEditorViewController(viewModel: viewModel)
        let sheetNavigationController = WMFComponentNavigationController(
            rootViewController: viewController,
            modalPresentationStyle: .formSheet
        )

        if isPadRegularWidth {
            let maximumHeight = navigationController.view.bounds.height * 0.8
            sheetNavigationController.preferredContentSize = CGSize(width: sheetWidth, height: min(contentHeight, maximumHeight))
        } else if let sheet = sheetNavigationController.sheetPresentationController {
            sheet.detents = [.custom(resolver: { context in
                let navigationBarHeight = sheetNavigationController.navigationBar.frame.height > 0
                ? sheetNavigationController.navigationBar.frame.height
                : 44
                return min(contentHeight + navigationBarHeight, context.maximumDetentValue)
            })]
        }

        self.sheetNavigationController = sheetNavigationController
        let presenter = navigationController.visibleViewController ?? navigationController
        presenter.present(sheetNavigationController, animated: true)
        return true
    }
}

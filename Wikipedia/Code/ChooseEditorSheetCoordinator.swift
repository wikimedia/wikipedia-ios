import UIKit
import SwiftUI
import WMFComponents
import WMFNativeLocalizations

final class ChooseEditorSheetCoordinator: Coordinator {

    var navigationController: UINavigationController
    private let theme: Theme
    private let didChoose: (WMFChooseEditorViewModel.EditMode, _ dontShowAgain: Bool) -> Void

    init(navigationController: UINavigationController, theme: Theme, didChoose: @escaping (WMFChooseEditorViewModel.EditMode, Bool) -> Void) {
        self.navigationController = navigationController
        self.theme = theme
        self.didChoose = didChoose
    }

    @discardableResult
    func start() -> Bool {
        let viewModel = WMFChooseEditorViewModel(
            didTapContinue: { mode, dontShowAgain in
                self.presentingViewController()?.dismiss(animated: true) {
                    self.didChoose(mode, dontShowAgain)
                }
            },
            didTapClose: {
                self.presentingViewController()?.dismiss(animated: true)
            }
        )

        let view = WMFChooseEditorView(viewModel: viewModel)
        let sizingController = UIHostingController(rootView: view)
        let width = navigationController.view.bounds.width
        let contentHeight = sizingController.sizeThatFits(in: CGSize(width: width, height: 0)).height

        let viewController = WMFChooseEditorViewController(viewModel: viewModel)
        let navVC = WMFComponentNavigationController(rootViewController: viewController, modalPresentationStyle: .pageSheet)

        if let sheet = navVC.sheetPresentationController {
            sheet.detents = [.custom(resolver: { context in
                let navBarHeight = navVC.navigationBar.frame.height > 0 ? navVC.navigationBar.frame.height : 44
                return min(contentHeight + navBarHeight, context.maximumDetentValue)
            })]
        }

        if let presentedViewController = navigationController.presentedViewController {
            presentedViewController.present(navVC, animated: true)
        } else {
            navigationController.present(navVC, animated: true)
        }

        return true
    }

    private func presentingViewController() -> UIViewController? {
        return navigationController.presentedViewController ?? navigationController
    }
}

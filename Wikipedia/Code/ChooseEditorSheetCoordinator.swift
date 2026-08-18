import UIKit
import SwiftUI
import WMFComponents
import WMFData
import WMFNativeLocalizations
import WMFTestKitchen

final class ChooseEditorSheetCoordinator: NSObject, Coordinator {

    var navigationController: UINavigationController
    private let theme: Theme
    private let initialMode: WMFEditMode
    private let didChoose: (WMFEditMode, _ dontShowAgain: Bool) -> Void
    private let didClose: () -> Void

    private weak var sheetNavigationController: WMFComponentNavigationController?
    private let editingInstrument = TestKitchenAdapter.shared.client.getInstrument(name: "apps-editing")

    init(
        navigationController: UINavigationController,
        theme: Theme,
        initialMode: WMFEditMode,
        didChoose: @escaping (WMFEditMode, Bool) -> Void,
        didClose: @escaping () -> Void
    ) {
        self.navigationController = navigationController
        self.theme = theme
        self.initialMode = initialMode
        self.didChoose = didChoose
        self.didClose = didClose
    }

    @discardableResult
    func start() -> Bool {
        let viewModel = WMFChooseEditorViewModel(
            initialMode: initialMode,
            didTapContinue: { mode, dontShowAgain in
                self.editingInstrument.submitInteraction(
                    action: "click",
                    actionSource: "edit_choice_select",
                    elementId: "edit_choice_submit",
                    actionContext: [
                        "edit_choice": mode.rawValue,
                        "is_default": dontShowAgain
                    ]
                )
                self.sheetNavigationController?.dismiss(animated: true) {
                    self.didChoose(mode, dontShowAgain)
                }
            },
            didTapClose: {
                self.editingInstrument.submitInteraction(
                    action: "click",
                    actionSource: "edit_choice_select",
                    elementId: "edit_choice_cancel"
                )
                self.sheetNavigationController?.dismiss(animated: true) {
                    self.didClose()
                }
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
        sheetNavigationController.presentationController?.delegate = self
        let presenter = navigationController.visibleViewController ?? navigationController
        presenter.present(sheetNavigationController, animated: true) {
            self.editingInstrument.submitInteraction(action: "impression", actionSource: "edit_choice_select")
        }
        return true
    }
}

extension ChooseEditorSheetCoordinator: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        editingInstrument.submitInteraction(
            action: "click",
            actionSource: "edit_choice_select",
            elementId: "edit_choice_cancel"
        )
        didClose()
    }
}

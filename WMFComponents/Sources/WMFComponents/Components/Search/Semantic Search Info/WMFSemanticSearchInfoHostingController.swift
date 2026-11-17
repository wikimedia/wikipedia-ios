import SwiftUI
import UIKit

/// Hosts the sheet that explains searching within articles. Present it inside a
/// `WMFComponentNavigationController`: the title and the close button are bar items. The sheet
/// fits its content, up to the full height.
public final class WMFSemanticSearchInfoHostingController: WMFComponentHostingController<WMFSemanticSearchInfoView>, WMFNavigationBarConfiguring {

    private static let fittingDetentIdentifier = UISheetPresentationController.Detent.Identifier("semanticSearchInfoFitting")

    private let viewModel: WMFSemanticSearchInfoViewModel

    public init(viewModel: WMFSemanticSearchInfoViewModel) {
        self.viewModel = viewModel
        super.init(rootView: WMFSemanticSearchInfoView(viewModel: viewModel))
        rootView = WMFSemanticSearchInfoView(viewModel: viewModel) { [weak self] height in
            self?.fitSheet(toContentHeight: height)
        }
    }

    @available(*, unavailable)
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBar()
    }

    private func configureNavigationBar() {
        let titleConfig = WMFNavigationBarTitleConfig(title: viewModel.title, customView: nil, alignment: .centerCompact)
        let closeConfig = WMFLargeCloseButtonConfig(imageType: .plainX, target: self, action: #selector(tappedClose), alignment: .leading)

        configureNavigationBar(
            titleConfig: titleConfig,
            closeButtonConfig: closeConfig,
            profileButtonConfig: nil,
            tabsButtonConfig: nil,
            searchBarConfig: nil,
            hideNavigationBarOnScroll: false
        )

        navigationItem.leftBarButtonItem?.accessibilityIdentifier = AccessibilityIdentifiers.Search.semanticSearchInfoCloseButton
    }

    private func fitSheet(toContentHeight contentHeight: CGFloat) {
        guard contentHeight > 0,
              let sheet = navigationController?.sheetPresentationController ?? sheetPresentationController else {
            return
        }

        let height = contentHeight + view.safeAreaInsets.top
        let detent = UISheetPresentationController.Detent.custom(identifier: Self.fittingDetentIdentifier) { context in
            min(height, context.maximumDetentValue)
        }
        sheet.animateChanges {
            sheet.detents = [detent]
        }
    }

    @objc private func tappedClose() {
        viewModel.close()
    }
}

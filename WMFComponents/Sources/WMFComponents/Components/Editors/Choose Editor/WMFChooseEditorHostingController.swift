import Foundation
import UIKit

public final class WMFChooseEditorViewController: WMFComponentHostingController<WMFChooseEditorView>, WMFNavigationBarConfiguring {

    private let viewModel: WMFChooseEditorViewModel

    public init(viewModel: WMFChooseEditorViewModel) {
        self.viewModel = viewModel
        super.init(rootView: WMFChooseEditorView(viewModel: viewModel))
    }

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
        configureNavigationBar(titleConfig: titleConfig, closeButtonConfig: closeConfig, profileButtonConfig: nil, tabsButtonConfig: nil, searchBarConfig: nil, hideNavigationBarOnScroll: false)
    }

    @objc private func tappedClose() {
        viewModel.tappedClose()
    }
}

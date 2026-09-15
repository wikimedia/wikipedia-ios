import UIKit
import SwiftUI

public final class WMFSemanticSearchHostingController: WMFComponentHostingController<WMFSemanticSearchView>, WMFNavigationBarConfiguring {

    private let viewModel: WMFSemanticSearchViewModel

    public init(viewModel: WMFSemanticSearchViewModel) {
        self.viewModel = viewModel
        super.init(rootView: WMFSemanticSearchView(viewModel: viewModel))
    }

    // Toolchain workaround: see the nonisolated deinit note in WMFComponentHostingController.
    nonisolated deinit {
    }

    @MainActor public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = theme.paperBackground
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBar()
    }

    public override func appEnvironmentDidChange() {
        super.appEnvironmentDidChange()
        view.backgroundColor = theme.paperBackground
    }

    private func configureNavigationBar() {
        let titleConfig = WMFNavigationBarTitleConfig(title: viewModel.localizedStrings.title, customView: nil, alignment: .centerCompact)
        let closeConfig = WMFLargeCloseButtonConfig(imageType: .plainX, target: self, action: #selector(tappedClose), alignment: .leading)

        configureNavigationBar(titleConfig: titleConfig, closeButtonConfig: closeConfig, profileButtonConfig: nil, tabsButtonConfig: nil, searchBarConfig: nil, hideNavigationBarOnScroll: false)
    }

    @objc private func tappedClose() {
        dismiss(animated: true)
    }
}

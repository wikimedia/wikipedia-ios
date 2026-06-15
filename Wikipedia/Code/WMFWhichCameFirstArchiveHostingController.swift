import UIKit
import SwiftUI
import MessageUI
import WMF
import WMFComponents
import WMFData
import WMFNativeLocalizations
import CocoaLumberjackSwift

public final class WMFWhichCameFirstArchiveHostingController: WMFComponentHostingController<WMFWhichCameFirstArchiveView>, WMFNavigationBarConfiguring {

    private let viewModel: WMFWhichCameFirstArchiveViewModel
    private let theme: Theme

    public init(viewModel: WMFWhichCameFirstArchiveViewModel, theme: Theme) {
        self.viewModel = viewModel
        self.theme = theme
        super.init(rootView: WMFWhichCameFirstArchiveView(viewModel: viewModel))
        viewModel.onShowScoreToast = { message in
            WMFToastManager.sharedInstance.showToast(message, sticky: false, dismissPreviousToasts: true)
        }
    }

    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBar()
    }

    private func configureNavigationBar() {
        let title = viewModel.localizedStrings.title + " " + viewModel.localizedStrings.archiveLabel
        let titleConfig = WMFNavigationBarTitleConfig(title: title, customView: nil, alignment: .centerCompact)
        let closeConfig = WMFLargeCloseButtonConfig(
            imageType: .plainX,
            target: self,
            action: #selector(didTapClose),
            alignment: .leading
        )
        configureNavigationBar(
            titleConfig: titleConfig,
            closeButtonConfig: closeConfig,
            profileButtonConfig: nil,
            tabsButtonConfig: nil,
            searchBarConfig: nil,
            hideNavigationBarOnScroll: false
        )
    }

    @objc private func didTapClose() {
        dismiss(animated: true)
    }
}

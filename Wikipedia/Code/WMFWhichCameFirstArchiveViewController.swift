import UIKit
import SwiftUI
import WMF
import WMFComponents
import WMFNativeLocalizations

public final class WMFWhichCameFirstArchiveViewController: WMFComponentHostingController<WMFWhichCameFirstArchiveView>, WMFNavigationBarConfiguring {

    private let viewModel: WMFWhichCameFirstArchiveViewModel

    public init(viewModel: WMFWhichCameFirstArchiveViewModel) {
        self.viewModel = viewModel
        viewModel.onShowScoreToast = { message in
            // Suppress the toast under VoiceOver — the score is already announced as the calendar cell's accessibility value
            guard !UIAccessibility.isVoiceOverRunning else { return }
            WMFToastManager.sharedInstance.showToast(message, sticky: false, dismissPreviousToasts: true)
        }
        super.init(rootView: WMFWhichCameFirstArchiveView(viewModel: viewModel))
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBar()
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        WMFToastManager.sharedInstance.dismissCurrentToast()
    }

    private func configureNavigationBar() {
        let titleConfig = WMFNavigationBarTitleConfig(title: "", customView: nil, alignment: .centerCompact)
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

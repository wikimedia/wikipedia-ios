import UIKit

public final class WMFHomeFeedWhatsDrivingSettingsViewController: WMFComponentHostingController<WMFHomeFeedWhatsDrivingSettingsView>, WMFNavigationBarConfiguring {

    private let viewModel: WMFHomeFeedWhatsDrivingSettingsViewModel
    private let closeButtonHandler: (() -> Void)?

    public init(viewModel: WMFHomeFeedWhatsDrivingSettingsViewModel, closeButtonHandler: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.closeButtonHandler = closeButtonHandler
        super.init(rootView: WMFHomeFeedWhatsDrivingSettingsView(viewModel: viewModel))
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBar()
    }

    private func configureNavigationBar() {
        let titleConfig = WMFNavigationBarTitleConfig(title: viewModel.title, customView: nil, alignment: .centerCompact)
        let closeButtonConfig: WMFLargeCloseButtonConfig? = closeButtonHandler != nil
            ? WMFLargeCloseButtonConfig(imageType: .plainX, target: self, action: #selector(tappedClose), alignment: .leading)
            : nil
        configureNavigationBar(titleConfig: titleConfig, closeButtonConfig: closeButtonConfig, profileButtonConfig: nil, tabsButtonConfig: nil, searchBarConfig: nil, hideNavigationBarOnScroll: false)
    }

    @objc private func tappedClose() {
        closeButtonHandler?()
    }
}

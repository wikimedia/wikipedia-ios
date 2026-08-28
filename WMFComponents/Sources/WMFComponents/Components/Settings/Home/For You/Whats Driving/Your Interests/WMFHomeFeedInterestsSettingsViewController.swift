import UIKit
import WMFData
import Foundation
import WMFNativeLocalizations

public final class WMFHomeFeedInterestsSettingsViewController: WMFComponentHostingController<WMFHomeFeedInterestsSettingsView>, WMFNavigationBarConfiguring {

    private let viewModel: WMFHomeFeedInterestsSettingsViewModel
    private let closeButtonHandler: (() -> Void)?

    public init(viewModel: WMFHomeFeedInterestsSettingsViewModel, closeButtonHandler: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.closeButtonHandler = closeButtonHandler
        super.init(rootView: WMFHomeFeedInterestsSettingsView(viewModel: viewModel))
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

        let isLeavingForGood = isMovingFromParent
            || isBeingDismissed
            || navigationController?.isBeingDismissed == true

        guard isLeavingForGood, viewModel.hasChanges else { return }
        NotificationCenter.default.post(name: WMFNSNotification.forYouInterestsDidChange, object: nil)
    }

    private func configureNavigationBar() {
        let titleConfig = WMFNavigationBarTitleConfig(title: viewModel.title, customView: nil, alignment: .centerCompact)
        let closeConfig = closeButtonHandler.map { _ in
            WMFLargeCloseButtonConfig(imageType: .plainX, target: self, action: #selector(close), alignment: .leading)
        }
        configureNavigationBar(titleConfig: titleConfig, closeButtonConfig: closeConfig, profileButtonConfig: nil, tabsButtonConfig: nil, searchBarConfig: nil, hideNavigationBarOnScroll: false)
    }

    @objc private func close() {
        closeButtonHandler?()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.logImpressionIfNeeded?()
    }
}

import UIKit
import WMFData
import Foundation
import WMFNativeLocalizations

public final class WMFHomeFeedInterestsSettingsViewController: WMFComponentHostingController<WMFHomeFeedInterestsSettingsView>, WMFNavigationBarConfiguring {

    public let viewModel: WMFHomeFeedInterestsSettingsViewModel
    private let closeButtonHandler: (() -> Void)?
    /// Asked before Back pops the screen, by the button and by the swipe. Return false to keep
    /// the screen, for example to show an alert first. Nil means Back always pops.
    public var shouldPopOnBack: (() -> Bool)?

    public init(viewModel: WMFHomeFeedInterestsSettingsViewModel, closeButtonHandler: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.closeButtonHandler = closeButtonHandler
        super.init(rootView: WMFHomeFeedInterestsSettingsView(viewModel: viewModel))
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.accessibilityIdentifier = AccessibilityIdentifiers.Interests.view
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

        guard isLeavingForGood else { return }
        viewModel.didLeave()
    }

    private func configureNavigationBar() {
        let titleConfig = WMFNavigationBarTitleConfig(title: viewModel.title, customView: nil, alignment: .centerCompact)
        let closeConfig = closeButtonHandler.map { _ in
            WMFLargeCloseButtonConfig(imageType: .plainX, target: self, action: #selector(close), alignment: .leading)
        }
        configureNavigationBar(titleConfig: titleConfig, closeButtonConfig: closeConfig, profileButtonConfig: nil, tabsButtonConfig: nil, searchBarConfig: nil, hideNavigationBarOnScroll: false)
        configureBackButton()
    }

    /// The Back button pops only when `shouldPopOnBack` agrees. `backAction` replaces the button's
    /// own action and keeps its look, so the screen before this one still names the button.
    private func configureBackButton() {
        guard shouldPopOnBack != nil else { return }
        navigationItem.backAction = UIAction { [weak self] _ in
            guard let self, self.shouldPopOnBackSwipe() else { return }
            self.navigationController?.popViewController(animated: true)
        }
    }

    @objc private func close() {
        closeButtonHandler?()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.logImpressionIfNeeded?()
    }
}

extension WMFHomeFeedInterestsSettingsViewController: WMFBackSwipeConfirming {
    public func shouldPopOnBackSwipe() -> Bool {
        shouldPopOnBack?() ?? true
    }
}

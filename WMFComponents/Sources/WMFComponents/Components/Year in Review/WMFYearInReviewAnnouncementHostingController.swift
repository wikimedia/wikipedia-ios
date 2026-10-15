import SwiftUI
import UIKit
import Combine

public final class WMFYearInReviewAnnouncementHostingController: WMFComponentHostingController<WMFYearInReviewAnnouncementView>, WMFNavigationBarConfiguring {

    private let viewModel: WMFYearInReviewAnnouncementViewModel
    private var cancellables = Set<AnyCancellable>()

    public init(viewModel: WMFYearInReviewAnnouncementViewModel) {
        self.viewModel = viewModel
        super.init(rootView: WMFYearInReviewAnnouncementView(viewModel: viewModel))
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    public override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }

    /// On iPad, the supported orientations above are not enough when the app supports multitasking.
    /// iPadOS 26 and later honors this preference instead, but only while this screen is visible,
    /// and the system may not honor it.
    @available(iOS 26.0, *)
    public override var prefersInterfaceOrientationLocked: Bool {
        return true
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        // The announcement is always light, whatever the system style is.
        overrideUserInterfaceStyle = .light

        // The artwork sets the color of the controls in its .riv, which is known only after it loads.
        // `@Published` sends the new value before the property changes, so use the value it sends.
        viewModel.$contentStyle
            .dropFirst()
            .sink { [weak self] contentStyle in
                guard let self else { return }
                WMFYearInReviewNavigationItems.applyTintColor(contentStyle.color, to: navigationItem)
            }
            .store(in: &cancellables)
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBar()
        (navigationController as? WMFComponentNavigationController)?.setTransparentAppearance(true)
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        lockToPortraitOnIPad()
    }

    // MARK: - Orientation

    /// Asks for portrait, then asks the system to keep it while this screen shows.
    private func lockToPortraitOnIPad() {
        guard UIDevice.current.userInterfaceIdiom == .pad else { return }

        view.window?.windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait)) { _ in }

        if #available(iOS 26.0, *) {
            setNeedsUpdateOfPrefersInterfaceOrientationLocked()
        }
    }

    // MARK: - Navigation bar

    /// Same navigation bar as the slides, without the W.
    private func configureNavigationBar() {
        WMFYearInReviewNavigationItems.configure(
            self,
            strings: WMFYearInReviewNavigationItems.Strings(
                wIconAccessibilityLabel: viewModel.localizedStrings.wIconAccessibilityLabel,
                closeButtonAccessibilityLabel: viewModel.localizedStrings.closeButtonAccessibilityLabel,
                moreButtonAccessibilityLabel: viewModel.localizedStrings.moreButtonAccessibilityLabel,
                learnMoreTitle: viewModel.localizedStrings.learnMoreButtonTitle,
                aboutInsightsTitle: viewModel.localizedStrings.aboutInsightsButtonTitle,
                shareFeedbackTitle: viewModel.localizedStrings.shareFeedbackButtonTitle
            ),
            tintColor: viewModel.contentColor,
            showsWikipediaLogo: false,
            closeAction: #selector(tappedClose),
            onLearnMore: { [weak self] in self?.viewModel.tappedLearnMore() },
            onAboutInsights: { [weak self] in self?.viewModel.tappedAboutInsights() },
            onShareFeedback: { [weak self] in self?.viewModel.tappedShareFeedback() }
        )
    }

    @objc private func tappedClose() {
        viewModel.tappedClose()
    }
}

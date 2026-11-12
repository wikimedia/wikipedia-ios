import UIKit
import Combine
import WMFData
import Foundation
import WMFNativeLocalizations

public final class WMFHomeFeedInterestsSettingsViewController: WMFComponentHostingController<WMFHomeFeedInterestsSettingsView>, WMFNavigationBarConfiguring {

    public let viewModel: WMFHomeFeedInterestsSettingsViewModel
    private let closeButtonHandler: (() -> Void)?
    private let doneButtonHandler: (() -> Void)?
    private var cancellables = Set<AnyCancellable>()

    private lazy var doneButton: UIBarButtonItem = {
        let configuration = WMFLargeCloseButtonConfig(imageType: .prominentCheck, target: self, action: #selector(tappedDone), alignment: .trailing)
        let button = UIBarButtonItem.closeNavigationBarButtonItem(config: configuration)
        button.accessibilityLabel = CommonStrings.doneTitle
        button.accessibilityIdentifier = AccessibilityIdentifiers.Interests.doneButton
        return button
    }()

    /// Pass `doneButtonHandler` to show Done in the navigation bar. Done is off while no interest
    /// is selected. Without the handler the screen has no Done, as on the For You interests.
    public init(viewModel: WMFHomeFeedInterestsSettingsViewModel, closeButtonHandler: (() -> Void)? = nil, doneButtonHandler: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.closeButtonHandler = closeButtonHandler
        self.doneButtonHandler = doneButtonHandler
        super.init(rootView: WMFHomeFeedInterestsSettingsView(viewModel: viewModel))
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.accessibilityIdentifier = AccessibilityIdentifiers.Interests.view
        bindDoneButton()
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
        guard doneButtonHandler != nil else { return }
        doneButton.tintColor = theme.link
        navigationItem.rightBarButtonItem = doneButton
    }

    /// The published selection drives the button, so Done follows every tap at once.
    private func bindDoneButton() {
        guard doneButtonHandler != nil else { return }
        Publishers.CombineLatest(viewModel.$selectedTopics, viewModel.$selectedArticleCount)
            .map { topics, articleCount in !topics.isEmpty || articleCount > 0 }
            .sink { [weak self] isEnabled in
                self?.doneButton.isEnabled = isEnabled
            }
            .store(in: &cancellables)
    }

    @objc private func close() {
        closeButtonHandler?()
    }

    @objc private func tappedDone() {
        doneButtonHandler?()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.logImpressionIfNeeded?()
    }
}

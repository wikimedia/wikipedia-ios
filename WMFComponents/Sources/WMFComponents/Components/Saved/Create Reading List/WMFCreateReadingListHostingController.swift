import UIKit
import SwiftUI
import Combine
import WMFNativeLocalizations

public final class WMFCreateReadingListHostingController: WMFComponentHostingController<WMFCreateReadingListView>, WMFNavigationBarConfiguring {

    public let viewModel: WMFCreateReadingListViewModel

    private var cancellables = Set<AnyCancellable>()

    private let createButtonTitle = WMFLocalizedString("reading-list-create-new-list-button-title", value: "Create reading list", comment: "Title for button allowing the user to create a new reading list.")

    private lazy var createButton: UIBarButtonItem = {
        let config = WMFLargeCloseButtonConfig(imageType: .prominentCheck, target: self, action: #selector(tappedCreate), alignment: .trailing)
        let button = UIBarButtonItem.closeNavigationBarButtonItem(config: config)
        button.accessibilityLabel = createButtonTitle
        button.accessibilityIdentifier = AccessibilityIdentifiers.CreateReadingList.createButton
        return button
    }()

    public init(viewModel: WMFCreateReadingListViewModel) {
        self.viewModel = viewModel
        super.init(rootView: WMFCreateReadingListView(viewModel: viewModel))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: - Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = theme.paperBackground
        bindViewModel()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBar()
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isBeingDismissed || navigationController?.isBeingDismissed == true {
            viewModel.didDismiss?()
        }
    }

    public override func appEnvironmentDidChange() {
        super.appEnvironmentDidChange()
        view.backgroundColor = theme.paperBackground
        configureNavigationBar()
    }

    public override func accessibilityPerformEscape() -> Bool {
        viewModel.tapClose()
        return true
    }

    // MARK: - View model

    private func bindViewModel() {
        viewModel.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateCreateButton()
            }
            .store(in: &cancellables)
    }

    private func updateCreateButton() {
        createButton.isEnabled = viewModel.isCreateButtonEnabled
    }

    // MARK: - Navigation bar

    private func configureNavigationBar() {
        let titleConfig = WMFNavigationBarTitleConfig(title: viewModel.title, customView: nil, alignment: .centerCompact)
        let closeButtonConfig = WMFLargeCloseButtonConfig(imageType: .plainX, target: self, action: #selector(tappedClose), alignment: .leading)
        configureNavigationBar(titleConfig: titleConfig, closeButtonConfig: closeButtonConfig, profileButtonConfig: nil, tabsButtonConfig: nil, searchBarConfig: nil, hideNavigationBarOnScroll: false)
        navigationItem.leftBarButtonItem?.accessibilityIdentifier = AccessibilityIdentifiers.CreateReadingList.closeButton
        createButton.tintColor = theme.link
        navigationItem.rightBarButtonItem = createButton
        updateCreateButton()
    }

    @objc private func tappedClose() {
        viewModel.tapClose()
    }

    @objc private func tappedCreate() {
        viewModel.tapCreate()
    }
}

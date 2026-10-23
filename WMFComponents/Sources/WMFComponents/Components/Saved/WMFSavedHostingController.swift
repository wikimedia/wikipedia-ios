import UIKit
import SwiftUI
import Combine
import WMFData
import WMFNativeLocalizations

public final class WMFSavedHostingController: WMFComponentHostingController<WMFSavedView>, WMFNavigationBarConfiguring {

    public let viewModel: WMFSavedViewModel

    private var cancellables = Set<AnyCancellable>()

    // Copies of the view model state the navigation bar depends on. `@Published` emits before the
    // property changes, so a sink reads the values it receives, not the view model.
    private var isEditingArticles = false
    private var profileButtonNeedsBadge = false

    public init(viewModel: WMFSavedViewModel) {
        self.viewModel = viewModel
        super.init(rootView: WMFSavedView(viewModel: viewModel))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = theme.paperBackground
        view.accessibilityIdentifier = AccessibilityIdentifiers.Saved.view
        isEditingArticles = viewModel.isEditing
        profileButtonNeedsBadge = viewModel.profileButtonNeedsBadge
        bindViewModel()

        if #available(iOS 18.0, *) {
            registerForTraitChanges([UITraitHorizontalSizeClass.self]) { (viewController: Self, previousTraitCollection: UITraitCollection) in
                guard UIDevice.current.userInterfaceIdiom == .pad,
                      previousTraitCollection.horizontalSizeClass != viewController.traitCollection.horizontalSizeClass else {
                    return
                }
                viewController.configureNavigationBar()
            }
        }

        viewModel.viewDidLoad()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.viewWillAppear()
        configureNavigationBar()
        if viewModel.isSearchPresented {
            hideCustomLeadingLargeTitleLabel()
        }
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.viewDidAppear()
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if !isMovingFromParent {
            viewModel.isSearchPresented = false
            hideCustomLeadingLargeTitleLabel()
        }
    }

    public override func appEnvironmentDidChange() {
        super.appEnvironmentDidChange()
        view.backgroundColor = theme.paperBackground
        themeNavigationBarCustomLeadingLargeTitle()
        navigationItem.rightBarButtonItems?.forEach { $0.tintColor = theme.text }
        updateProfileButton()
    }

    // MARK: - View model

    private func bindViewModel() {
        viewModel.$isSearchPresented
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] isPresented in
                if isPresented {
                    self?.hideCustomLeadingLargeTitleLabel()
                } else {
                    self?.showCustomLeadingLargeTitleLabel()
                }
            }
            .store(in: &cancellables)

        viewModel.$isEditing
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] isEditing in
                guard let self else { return }
                self.isEditingArticles = isEditing
                if isEditing {
                    showCancelEditingButton()
                } else {
                    configureNavigationBar()
                }
            }
            .store(in: &cancellables)

        viewModel.$profileButtonNeedsBadge
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] profileButtonNeedsBadge in
                guard let self else { return }
                self.profileButtonNeedsBadge = profileButtonNeedsBadge
                updateProfileButton()
            }
            .store(in: &cancellables)
    }

    // MARK: - Navigation bar

    private func configureNavigationBar() {
        let titleConfig = WMFNavigationBarTitleConfig(title: CommonStrings.savedTabTitle, customView: nil, alignment: .customLeadingLarge)

        let profileButtonConfig = WMFNavigationBarProfileButtonConfig(
            title: CommonStrings.account,
            accessibilityLabelNoNotifications: CommonStrings.profileButtonTitle,
            accessibilityLabelHasNotifications: CommonStrings.profileButtonBadgeTitle,
            accessibilityHint: CommonStrings.profileButtonAccessibilityHint,
            needsBadge: profileButtonNeedsBadge,
            target: self,
            action: #selector(didTapProfile)
        )

        let tabsButtonConfig = WMFNavigationBarTabsButtonConfig(
            title: CommonStrings.tabsTitle,
            accessibilityLabel: CommonStrings.tabsButtonAccessibilityLabel,
            accessibilityHint: CommonStrings.tabsButtonAccessibilityHint,
            target: self,
            action: #selector(didTapTabs),
            leadingBarButtonItem: moreBarButtonItem
        )

        configureNavigationBar(titleConfig: titleConfig, closeButtonConfig: nil, profileButtonConfig: profileButtonConfig, tabsButtonConfig: tabsButtonConfig, searchBarConfig: nil, hideNavigationBarOnScroll: false)

        if isEditingArticles {
            showCancelEditingButton()
        }
    }

    private func showCancelEditingButton() {
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(didTapCancelEditing))
        cancelButton.tintColor = theme.text
        cancelButton.accessibilityIdentifier = AccessibilityIdentifiers.Saved.editingCancelButton
        navigationItem.rightBarButtonItems = [cancelButton]
    }

    private func updateProfileButton() {
        guard !isEditingArticles else { return }
        updateNavigationBarProfileButton(needsBadge: profileButtonNeedsBadge, needsBadgeLabel: CommonStrings.profileButtonBadgeTitle, noBadgeLabel: CommonStrings.profileButtonTitle)
    }

    // MARK: - More menu

    private lazy var moreBarButtonItem: UIBarButtonItem = {
        let deferredMenu = UIDeferredMenuElement.uncached { [weak self] completion in
            completion(self?.overflowMenuElements() ?? [])
        }
        let button = UIBarButtonItem(image: WMFSFSymbolIcon.for(symbol: .ellipsis), primaryAction: nil, menu: UIMenu(title: "", children: [deferredMenu]))
        button.accessibilityLabel = CommonStrings.moreButton
        button.accessibilityIdentifier = AccessibilityIdentifiers.Saved.moreButton
        if #available(iOS 26.0, *) {
            button.sharesBackground = false
        }
        return button
    }()

    private func overflowMenuElements() -> [UIMenuElement] {
        let sortActions = WMFReadingListSortOrder.allCases.map { sortOrder in
            UIAction(title: Self.title(for: sortOrder), state: viewModel.sortOrder == sortOrder ? .on : .off) { [weak self] _ in
                self?.viewModel.setSortOrder(sortOrder)
            }
        }
        let sortMenu = UIMenu(title: CommonStrings.sortActionTitle, options: .singleSelection, children: sortActions)

        let editAction = UIAction(title: CommonStrings.editContextMenuTitle) { [weak self] _ in
            self?.viewModel.toggleEditing()
        }

        return [sortMenu, editAction]
    }

    private static func title(for sortOrder: WMFReadingListSortOrder) -> String {
        switch sortOrder {
        case .byTitle:
            return CommonStrings.sortAlertOptionByTitle
        case .byRecentlyAdded:
            return CommonStrings.sortAlertOptionByRecentlyAdded
        }
    }

    // MARK: - Actions

    @objc public func didTapProfile() {
        viewModel.profileButtonTapped()
    }

    @objc public func didTapTabs() {
        viewModel.tabsButtonTapped()
    }

    @objc private func didTapCancelEditing() {
        viewModel.cancelEditing()
    }
}

import SwiftUI
import Foundation
import WMFData

public class WMFArticleTabsHostingController<HostedView: View>: WMFComponentHostingController<HostedView>, WMFNavigationBarConfiguring {
    
    lazy var addTabButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: WMFSFSymbolIcon.for(symbol: .add), style: .plain, target: self, action: #selector(tappedAdd))
        return button
    }()
    
    lazy var overflowButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: WMFSFSymbolIcon.for(symbol: .ellipsisCircle), primaryAction: nil, menu: overflowMenu)
        return button
    }()
    
    private let viewModel: WMFArticleTabsViewModel
    private let doneButtonText: String
    private let articleTabsCount: Int
    private var format: String?
    private var dataController: WMFArticleTabsDataController

    public init(rootView: HostedView, viewModel: WMFArticleTabsViewModel, doneButtonText: String, articleTabsCount: Int) {
        self.viewModel = viewModel
        self.doneButtonText = doneButtonText
        self.articleTabsCount = articleTabsCount
        dataController = WMFArticleTabsDataController.shared
        super.init(rootView: rootView)
        
        // Defining format outside the block fixes a retain cycle on WMFArticleTabsViewModel
        format = viewModel.localizedStrings.navBarTitleFormat
        viewModel.updateNavigationBarTitleAction = { [weak self] numTabs in
            let newNavigationBarTitle = String.localizedStringWithFormat(self?.format ?? "", numTabs)
            self?.configureNavigationBar(newNavigationBarTitle.lowercased())
        }
    }
    
    @MainActor public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        configureNavigationBar()
        
        if dataController.shouldShowMoreDynamicTabsV2 {
            navigationItem.rightBarButtonItems = [addTabButton, overflowButton]
        } else {
            navigationItem.rightBarButtonItem = addTabButton
        }
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.loggingDelegate?.logArticleTabsOverviewImpression()
    }

    private func configureNavigationBar(_ title: String? = nil) {
        let newNavigationBarTitle = String.localizedStringWithFormat(self.format ?? "", articleTabsCount)
        let titleConfig = WMFNavigationBarTitleConfig(title: title ?? newNavigationBarTitle, customView: nil, alignment: .centerCompact)

        let closeConfig = WMFNavigationBarCloseButtonConfig(text: doneButtonText, target: self, action: #selector(tappedDone), alignment: .leading)

        configureNavigationBar(titleConfig: titleConfig, closeButtonConfig: closeConfig, profileButtonConfig: nil, tabsButtonConfig: nil, searchBarConfig: nil, hideNavigationBarOnScroll: false)
    }
    
    @objc func tappedDone() {
        viewModel.didTapDone()
    }
    
    @objc private func tappedAdd() {
        viewModel.didTapAddTab()
    }

    @objc private func tappedOverflow() {
        viewModel.didTapAddTab()
    }
    
    var overflowMenu: UIMenu {
        let closeAllTabs = UIAction(
            title: viewModel.localizedStrings.closeAllTabs,
            image: WMFIcon.closeTabs,
            attributes: [.destructive],
            handler: { [weak self] _ in
            Task {
                await self?.presentCloseAllTabsConfirmationDialog()
                self?.viewModel.loggingDelegate?.logArticleTabsOverviewTappedCloseAllTabs()
            }
        })
        
        let mainMenu = UIMenu(title: String(), children: [closeAllTabs])

        return mainMenu
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.userDidTakeScreenshotNotification, object: nil)
    }

    private func presentCloseAllTabsConfirmationDialog() async {
        let button1Title = viewModel.localizedStrings.cancelActionTitle
        let button2Title = viewModel.localizedStrings.closeAllTabs
        guard let tabsCount = try? await dataController.tabsCount() else { return }
        

        let alert = UIAlertController(
            title: viewModel.localizedStrings.closeAllTabsTitle(tabsCount),
            message: viewModel.localizedStrings.closeAllTabsSubtitle(tabsCount),
            preferredStyle: .alert
        )
        
        let action1 = UIAlertAction(title: button1Title, style: .cancel, handler: { [weak self] _ in
            self?.viewModel.loggingDelegate?.logArticleTabsOverviewTappedCloseAllTabsConfirmCancel()
        })
        
        let action2 = UIAlertAction(title: button2Title, style: .destructive) { [weak self] _ in
            guard let self else { return }
            Task {
                self.viewModel.didTapCloseAllTabs()
                self.viewModel.loggingDelegate?.logArticleTabsOverviewTappedCloseAllTabsConfirmClose()
            }
        }
        
        alert.addAction(action1)
        alert.addAction(action2)
        present(alert, animated: true)
    }
}

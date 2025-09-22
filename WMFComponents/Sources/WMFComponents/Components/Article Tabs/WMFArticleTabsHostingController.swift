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
            self?.configureNavigationBar(newNavigationBarTitle)
        }
    }
    
    @MainActor public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        configureNavigationBar()
        
        if dataController.shouldShowMoreDynamicTabs {
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
        dismiss(animated: true, completion: nil)
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
            }
        })
        
        let hideArticleSuggestions = UIAction(title: viewModel.localizedStrings.hideSuggestedArticlesTitle, image: WMFSFSymbolIcon.for(symbol: .eyeSlash), handler: { [weak self] _ in
            guard let self else { return }
            self.dataController.shouldHideArticleSuggestions.toggle()
            self.overflowButton.menu = self.overflowMenu
            
        })
        
        let showArticleSuggestions = UIAction(title: viewModel.localizedStrings.showSuggestedArticlesTitle, image: WMFSFSymbolIcon.for(symbol: .eye), handler: { [weak self] _ in
            guard let self else { return }
            self.dataController.shouldHideArticleSuggestions.toggle()
            self.overflowButton.menu = self.overflowMenu
            
        })
        
        var children: [UIMenuElement]
        if dataController.shouldShowArticleSuggestions {
            if dataController.shouldHideArticleSuggestions {
                children = [showArticleSuggestions, closeAllTabs]
            } else {
                children = [hideArticleSuggestions, closeAllTabs]
            }
        } else {
            children = [closeAllTabs]
        }
        let mainMenu = UIMenu(title: String(), children: children)

        return mainMenu
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.userDidTakeScreenshotNotification, object: nil)
    }

    private func presentCloseAllTabsConfirmationDialog() async {
        let button1Title = viewModel.localizedStrings.cancelActionTitle
        let button2Title = viewModel.localizedStrings.closeAllTabs

        let alert = UIAlertController(
            title: viewModel.localizedStrings.closeAllTabsTitle,
            message: viewModel.localizedStrings.closeAllTabsSubtitle,
            preferredStyle: .alert
        )
        
        let action1 = UIAlertAction(title: button1Title, style: .cancel)
        
        let action2 = UIAlertAction(title: button2Title, style: .destructive) { [weak self] _ in
            guard let self else { return }
            Task {
                self.viewModel.didTapCloseAllTabs()
            }
        }
        
        alert.addAction(action1)
        alert.addAction(action2)
        present(alert, animated: true)
    }
}

import UIKit
import SwiftUI
import WMFComponents
import WMFData
import CocoaLumberjackSwift

final class TabsOverviewCoordinator: Coordinator {
    var navigationController: UINavigationController
    var theme: Theme
    let dataStore: MWKDataStore
    private let dataController: WMFArticleTabsDataController
    private let summaryController: ArticleSummaryController
    private var newTabCoordinator: NewArticleTabCoordinator?
    private let userDefaultsStore = WMFDataEnvironment.current.userDefaultsStore
    private var hostingController: UIHostingController<WMFNewArticleTabSettingsView>?
    private var viewModel: WMFNewArticleTabSettingsViewModel?

    @discardableResult
    func start() -> Bool {
        presentTabs()
        return true
    }

    public init(navigationController: UINavigationController, theme: Theme, dataStore: MWKDataStore) {
        self.navigationController = navigationController
        self.theme = theme
        self.dataStore = dataStore
        let dataController = WMFArticleTabsDataController.shared
        self.dataController = dataController
        self.summaryController = dataStore.articleSummaryController
    }
    
    private func surveyViewController() -> UIViewController {
        let subtitle = WMFLocalizedString("tabs-survey-title", value: "Help improve the tabs feature. Are you satisfied with this feature?", comment: "Title for article tabs survey")
        
        let surveyLocalizedStrings = WMFSurveyViewModel.LocalizedStrings(
            title: CommonStrings.satisfactionSurveyTitle,
            cancel: CommonStrings.cancelActionTitle,
            submit: CommonStrings.surveySubmitActionTitle,
            subtitle: subtitle,
            instructions: nil,
            otherPlaceholder: CommonStrings.surveyAdditionalThoughts
        )

        let surveyOptions = [
            WMFSurveyViewModel.OptionViewModel(text: CommonStrings.surveyVerySatisfied, apiIdentifer: "1"),
            WMFSurveyViewModel.OptionViewModel(text: CommonStrings.surveySatisfied, apiIdentifer: "2"),
            WMFSurveyViewModel.OptionViewModel(text: CommonStrings.surveyNeutral, apiIdentifer: "3"),
            WMFSurveyViewModel.OptionViewModel(text: CommonStrings.surveyUnsatisfied, apiIdentifer: "4"),
            WMFSurveyViewModel.OptionViewModel(text: CommonStrings.surveyVeryUnsatisfied, apiIdentifer: "5")
        ]

        let surveyView = WMFSurveyView(viewModel: WMFSurveyViewModel(localizedStrings: surveyLocalizedStrings, options: surveyOptions, selectionType: .single, shouldShowMultilineText: true), cancelAction: { [weak self] in
            ArticleTabsFunnel.shared.logFeedbackClose()
            self?.navigationController.presentedViewController?.dismiss(animated: true)
        }, submitAction: { [weak self] options, otherText in
            ArticleTabsFunnel.shared.logFeedbackSubmit(selectedItems: options, comment: otherText)
            self?.navigationController.presentedViewController?.dismiss(animated: true, completion: {
                let image = UIImage(systemName: "checkmark.circle.fill")
                WMFAlertManager.sharedInstance.showBottomAlertWithMessage(CommonStrings.feedbackSurveyToastTitle, subtitle: nil, image: image, type: .custom, customTypeName: "feedback-submitted", dismissPreviousAlerts: true)
            })
        })

        let hostedView = WMFComponentHostingController(rootView: surveyView)
        return hostedView
    }
    
    private func presentTabs() {
        
        let didTapTab: (WMFArticleTabsDataController.WMFArticleTab) -> Void = { [weak self] tab in
            self?.tappedTab(tab)
        }
        
        let didTapAddTab: () -> Void = { [weak self] in

            guard let self else { return }
            self.tappedAddTab()
        }
        
        let didTapOpenPreferences: () -> Void = { [weak self] in
            self?.didTapOpenTabsPreferences()
        }
        
        let showSurveyClosure = { [weak self] in
            if let shouldShowSurvey = self?.dataController.shouldShowSurvey(), shouldShowSurvey {
                guard let presentedVC = self?.navigationController.presentedViewController else { return }
                let surveyVC = self?.surveyViewController()
                guard let surveyVC else { return }
                ArticleTabsFunnel.shared.logFeedbackImpression()
                presentedVC.present(surveyVC, animated: true)
                
                surveyVC.modalPresentationStyle = .pageSheet
                if let sheet = surveyVC.sheetPresentationController {
                    sheet.detents = [.medium()]
                    sheet.prefersGrabberVisible = false
                }
            }
        }

        let needsMoreDynamicTabs = dataController.shouldShowMoreDynamicTabs

        let pageTitle = needsMoreDynamicTabs ? CommonStrings.newTab : nil
        let pageSubtitle = needsMoreDynamicTabs ? CommonStrings.tabThumbnailSubtitle : CommonStrings.mainPageSubtitle
        let pageDescription = needsMoreDynamicTabs ? CommonStrings.tabThumbanailDescription : CommonStrings.mainPageDescription

        let localizedStrings = WMFArticleTabsViewModel.LocalizedStrings(
            navBarTitleFormat: WMFLocalizedString("tabs-navbar-title-format", value: "{{PLURAL:%1$d|%1$d tab|%1$d tabs}}", comment: "$1 is the amount of tabs. Navigation title for tabs, displaying how many open tabs."),
            mainPageTitle: pageTitle,
            mainPageSubtitle: pageSubtitle,
            mainPageDescription: pageDescription,
            closeTabAccessibility: WMFLocalizedString("tabs-close-tab", value: "Close tab", comment: "Accessibility label for close tab button"),
            openTabAccessibility: WMFLocalizedString("tabs-open-tab", value: "Open tab", comment: "Accessibility label for opening a tab"),
            tabsPreferencesTitle: CommonStrings.tabsPreferencesTitle
        )
        
        let articleTabsViewModel = WMFArticleTabsViewModel(
            dataController: dataController,
            localizedStrings: localizedStrings,
            loggingDelegate: self,
            didTapTab: didTapTab,
            didTapAddTab: didTapAddTab,
            didTapOpenTabs: didTapOpenPreferences)
        let articleTabsView = WMFArticleTabsView(viewModel: articleTabsViewModel)
        
        let hostingController = WMFArticleTabsHostingController(rootView: articleTabsView, viewModel: articleTabsViewModel,
                                                                doneButtonText: CommonStrings.doneTitle)
        let navVC = WMFComponentNavigationController(rootViewController: hostingController, modalPresentationStyle: .overFullScreen)

        navigationController.present(navVC, animated: true) { [weak self] in
            self?.dataController.updateSurveyDataTabsOverviewSeenCount()
             guard self != nil else { return }
             showSurveyClosure()
         }
    }
    
    private func didTapOpenTabsPreferences() {
        let viewModel = WMFNewArticleTabSettingsViewModel(
            title: CommonStrings.tabsPreferencesTitle,
            header: CommonStrings.newTabTheme,
            options: [
                CommonStrings.recommendations,
                CommonStrings.didyouknow
            ],
            saveSelection: { [weak self] selectedIndex in
                self?.saveSelection(selectedIndex: selectedIndex)
            },
            selectedIndex: self.getSelectedIndex(),
            loggingDelegate: self
        )

        self.viewModel = viewModel

        let view = WMFNewArticleTabSettingsView(viewModel: viewModel)
        let hostingController = UIHostingController(rootView: view)
        hostingController.title = CommonStrings.tabsPreferencesTitle
        hostingController.navigationItem.largeTitleDisplayMode = .never

        hostingController.navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: CommonStrings.doneTitle,
            style: .done,
            target: self,
            action: #selector(self.doneButtonTapped)
        )

        self.hostingController = hostingController

        let navController = WMFComponentNavigationController(rootViewController: hostingController)

        let presenter = navigationController.presentedViewController ?? navigationController
        presenter.present(navController, animated: true) { [weak self] in
            self?.saveSelection(selectedIndex: viewModel.selectedIndex)
        }
    }

    @objc private func doneButtonTapped() {
        hostingController?.navigationController?.dismiss(animated: true)
    }

    private func getSelectedIndex() -> Int {
        let isBYREnabled = (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.developerSettingsMoreDynamicTabsBYR.rawValue)) ?? false
        let isDYKEnabled = (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.developerSettingsMoreDynamicTabsDYK.rawValue)) ?? false

        return (isBYREnabled) ? 0 : (isDYKEnabled) ? 1 : 0
    }
    
    private func saveSelection(selectedIndex: Int) {
        let isBYR = selectedIndex == 0
        let isDYK = selectedIndex == 1

        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.developerSettingsMoreDynamicTabsBYR.rawValue, value: isBYR)
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.developerSettingsMoreDynamicTabsDYK.rawValue, value: isDYK)

        dataController.moreDynamicTabsBYRIsEnabled = isBYR
        dataController.moreDynamicTabsDYKIsEnabled = isDYK
    }
    
    private func tappedTab(_ tab: WMFArticleTabsDataController.WMFArticleTab) {
        // If navigation controller is already displaying tab, just dismiss without pushing on any more tabs.
        if let displayedArticleViewController = navigationController.viewControllers.last as? ArticleViewController,
           let displayedTabIdentifier = displayedArticleViewController.coordinator?.tabIdentifier {
            if displayedTabIdentifier == tab.identifier {
                navigationController.dismiss(animated: true)
                return
            }
        }
        
        // Only push on last article
        if let article = tab.articles.last {
            guard let siteURL = article.project.siteURL,
                  let articleURL = siteURL.wmf_URL(withTitle: article.title) else {
                return
            }
            
            let tabConfig = ArticleTabConfig.assignParticularTabAndSetToCurrent(WMFArticleTabsDataController.Identifiers(tabIdentifier: tab.identifier, tabItemIdentifier: article.identifier))

            let needsMoreDynamicTabs = dataController.shouldShowMoreDynamicTabs

            // If we're showing more dynamic tabs, we need to push to the new tab experience instead of main page
            if needsMoreDynamicTabs {
                if tab.articles.last?.isMain == true {
                    self.newTabCoordinator = NewArticleTabCoordinator(navigationController: self.navigationController, dataStore: self.dataStore, theme: self.theme, tabIdentifier: WMFArticleTabsDataController.Identifiers(tabIdentifier: tab.identifier, tabItemIdentifier: article.identifier))
                    self.newTabCoordinator?.start()
                } else {
                    let articleCoordinator = ArticleCoordinator(navigationController: navigationController, articleURL: articleURL, dataStore: MWKDataStore.shared(), theme: theme, needsAnimation: false, source: .undefined, isRestoringState: true, tabConfig: tabConfig)
                    articleCoordinator.start()
                }
            } else {
                // isRestoringState = true allows for us to retain the previous scroll position
                let articleCoordinator = ArticleCoordinator(navigationController: navigationController, articleURL: articleURL, dataStore: MWKDataStore.shared(), theme: theme, needsAnimation: false, source: .undefined, isRestoringState: true, tabConfig: tabConfig)
                articleCoordinator.start()
            }
        }
        navigationController.dismiss(animated: true)
    }
    
    private func tappedAddTab() {

        if dataController.shouldShowMoreDynamicTabs {
            let isOnStack = self.navigationController.viewControllers.contains { $0 is SearchViewController }
            // do not push a new tab if the user just came from a new tab
            if isOnStack {
                navigationController.dismiss(animated: true)
            } else {
                navigationController.dismiss(animated: true) {
                    self.newTabCoordinator = NewArticleTabCoordinator(navigationController: self.navigationController, dataStore: self.dataStore, theme: self.theme)
                    self.newTabCoordinator?.start()
                }
            }
            return
        }
        guard let siteURL = dataStore.languageLinkController.appLanguage?.siteURL,
              let articleURL = siteURL.wmf_URL(withTitle: "Main Page") else {
            return
        }
        
        let articleCoordinator = ArticleCoordinator(navigationController: navigationController, articleURL: articleURL, dataStore: MWKDataStore.shared(), theme: theme, needsAnimation: false, source: .undefined, tabConfig: .assignNewTabAndSetToCurrent)
        ArticleTabsFunnel.shared.logAddNewBlankTab()
        articleCoordinator.start()
        
        navigationController.dismiss(animated: true)
    }
}

extension TabsOverviewCoordinator: WMFArticleTabsLoggingDelegate {

    func logArticleTabsOverviewImpression() {
        ArticleTabsFunnel.shared.logTabsOverviewImpression()
    }
    
    func logArticleTabsArticleClick(wmfProject: WMFProject?) {
        if let url = wmfProject?.siteURL, let project =  WikimediaProject(siteURL:url) {
            ArticleTabsFunnel.shared.logArticleClick(project: project)
        }
    }

    func logTabsOverviewScreenshot() {
        ArticleTabsFunnel.shared.logTabsOverviewScreenshot()
    }
}

extension TabsOverviewCoordinator: WMFNewArticleTabSettingsLoggingDelegate {
    func logPreference(index: Int) {
        ArticleTabsFunnel.shared.logTabsPreferenceClick(action: index == 0 ? .recommendationPrefClick : .didYouKnowPrefClick)
    }
}

/// Manages the lifecycle of TabsOverviewCoordinator independently of article tabs.
/// Ensures the tabs UI works even if the current article tab is closed.
final class TabsCoordinatorManager {

    static let shared = TabsCoordinatorManager()

    private var tabsOverviewCoordinator: TabsOverviewCoordinator?

    func presentTabsOverview(from navigationController: UINavigationController, theme: Theme, dataStore: MWKDataStore) {
        let coordinator = TabsOverviewCoordinator(navigationController: navigationController, theme: theme, dataStore: dataStore)
        self.tabsOverviewCoordinator = coordinator

        coordinator.start()
    }
}

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
    
    @discardableResult
    func start() -> Bool {
        if shouldShowEntryPoint() {
            presentTabs()
            return true
        } else {
            return false
        }
    }
    
    func shouldShowEntryPoint() -> Bool {
        return dataController.shouldShowArticleTabs
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
            self?.logArticleTabsFeedbackClose()
            self?.navigationController.presentedViewController?.dismiss(animated: true)
        }, submitAction: { [weak self] options, otherText in
            self?.logArticleTabsFeedback(selectedItems: options, comment: otherText)
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
            self?.tappedAddTab()
        }
        
        let showSurveyClosure = { [weak self] in
            if let shouldShowSurvey = self?.dataController.shouldShowSurvey(), shouldShowSurvey {
                guard let presentedVC = self?.navigationController.presentedViewController else { return }
                let surveyVC = self?.surveyViewController()
                guard let surveyVC else { return }
                presentedVC.present(surveyVC, animated: true)
                
                surveyVC.modalPresentationStyle = .pageSheet
                if let sheet = surveyVC.sheetPresentationController {
                    sheet.detents = [.medium()]
                    sheet.prefersGrabberVisible = false
                }
            }
        }
        
        let localizedStrings = WMFArticleTabsViewModel.LocalizedStrings(
            navBarTitleFormat: WMFLocalizedString("tabs-navbar-title-format", value: "{{PLURAL:%1$d|%1$d tab|%1$d tabs}}", comment: "$1 is the amount of tabs. Navigation title for tabs, displaying how many open tabs."),
            mainPageSubtitle: WMFLocalizedString("tabs-main-page-subtitle", value: "Wikipedia’s daily highlights", comment: "Main page subtitle"),
            mainPageDescription: WMFLocalizedString("tabs-main-page-description", value: "Discover featured articles, the latest news, interesting facts, and key stats on Wikipedia’s main page.", comment: "Main page description"),
            closeTabAccessibility: WMFLocalizedString("tabs-close-tab", value: "Close tab", comment: "Accessibility label for close tab button"),
            openTabAccessibility: WMFLocalizedString("tabs-open-tab", value: "Open tab", comment: "Accessibility label for opening a tab")
        )
        
        let articleTabsViewModel = WMFArticleTabsViewModel(dataController: dataController, localizedStrings: localizedStrings, loggingDelegate: self, didTapTab: didTapTab, didTapAddTab: didTapAddTab)
        let articleTabsView = WMFArticleTabsView(viewModel: articleTabsViewModel)
        
        let hostingController = WMFArticleTabsHostingController(rootView: articleTabsView, viewModel: articleTabsViewModel,
                                                                doneButtonText: CommonStrings.doneTitle)
        let navVC = WMFComponentNavigationController(rootViewController: hostingController, modalPresentationStyle: .overFullScreen)

        navigationController.present(navVC, animated: true) { [weak self] in
            self?.dataController.updateSurveyDataTabsOverviewSeenCount()
             guard let self else { return }
             
             if self.dataController.shouldShowArticleTabs {
                 showSurveyClosure()
             }
         }
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

            // isRestoringState = true allows for us to retain the previous scroll position
            let articleCoordinator = ArticleCoordinator(navigationController: navigationController, articleURL: articleURL, dataStore: MWKDataStore.shared(), theme: theme, needsAnimation: false, source: .undefined, isRestoringState: true, tabConfig: tabConfig)
            articleCoordinator.start()
        }

        navigationController.dismiss(animated: true)
    }
    
    private func tappedAddTab() {
        guard let siteURL = dataStore.languageLinkController.appLanguage?.siteURL,
              let articleURL = siteURL.wmf_URL(withTitle: "Main Page") else {
            return
        }
        
        let articleCoordinator = ArticleCoordinator(navigationController: navigationController, articleURL: articleURL, dataStore: MWKDataStore.shared(), theme: theme, needsAnimation: false, source: .undefined, tabConfig: .assignNewTabAndSetToCurrent)
        articleCoordinator.start()
        
        navigationController.dismiss(animated: true)
    }
}

extension UIViewController {
    @objc func dismissSelf() {
        self.dismiss(animated: true, completion: nil)
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

    func logArticleTabsFeedback(selectedItems: [String], comment: String?) {
        ArticleTabsFunnel.shared.logFeedbackSubmit(selectedItems: selectedItems, comment: comment)
    }

    func logArticleTabsFeedbackClose() {
        ArticleTabsFunnel.shared.logFeedbackClose()
    }

}

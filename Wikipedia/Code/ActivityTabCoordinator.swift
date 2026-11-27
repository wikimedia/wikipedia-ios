import UIKit
import WMF
import WMFComponents
import WMFData
import WMFNativeLocalizations

/// Builds the Activity tab and logs the tab bar taps that lead to it.
@MainActor
final class ActivityTabCoordinator: TabRootCoordinator {

    let tab: WMFAppTabType = .recent

    private var tabNavigationController: UINavigationController?
    var navigationController: UINavigationController {
        guard let tabNavigationController else {
            fatalError("ActivityTabCoordinator.navigationController accessed before attach(navigationController:)")
        }
        return tabNavigationController
    }

    private var theme: Theme
    private let dataStore: MWKDataStore

    /// Nil until the tab is built. The Year in Review badge reads this so that it never builds the tab.
    private(set) var activityTabViewController: WMFActivityTabViewController?

    init(theme: Theme, dataStore: MWKDataStore) {
        self.theme = theme
        self.dataStore = dataStore
    }

    var viewController: WMFActivityTabViewController {
        if let activityTabViewController {
            return activityTabViewController
        }
        let vc = makeActivityTabViewController()
        vc.tabBarItem.image = UIImage(named: "tabbar-recent")
        vc.tabBarItem.accessibilityIdentifier = AccessibilityIdentifiers.RootTab.activityButton
        vc.title = WMFCommonStringsWrapper.activityTitle
        activityTabViewController = vc
        return vc
    }

    var rootViewController: UIViewController {
        viewController
    }

    func attach(navigationController: UINavigationController) {
        tabNavigationController = navigationController
    }

    @discardableResult
    func start() -> Bool {
        navigationController.setViewControllers([viewController], animated: false)
        return true
    }

    func apply(theme: Theme) {
        self.theme = theme
    }

    func incrementActivityTabVisitCount() {
        Task {
            await WMFActivityTabDataController.shared.incrementActivityTabVisitCount()
        }
    }

    private func makeActivityTabViewController() -> WMFActivityTabViewController {
        let onWikipediaiOS = WMFLocalizedString(
            "activity-tab-hours-on-wikipedia-ios",
            value: "ON WIKIPEDIA iOS",
            comment: "Activity tab header for on Wikipedia iOS, entirely capitalized except for iOS, which maintains its proper capitalization"
        )

        let timeSpentReading = WMFLocalizedString(
            "activity-tab-time-spent-reading",
            value: "Time spent reading this week",
            comment: "Subtitle to describe the amount of time read this week which will be displayed above with hours and minutes"
        )

        let activityTabDataController = WMFActivityTabDataController()

        func usernamesReading(username: String) -> String {
            let format = WMFLocalizedString(
                "activity-tab-usernames-reading-title",
                value: "%1$@'s reading",
                comment: "Activity tab header, includes username and their reading, like User's reading where $1 is replaced with the username."
            )
            return String.localizedStringWithFormat(format, username)
        }

        let noUsernameReading = WMFLocalizedString("activity-tab-no-username-reading-title", value: "Your reading", comment: "Activity tab header, for when there is no username.")

        func hoursMinutesRead(hours: Int, minutes: Int) -> String {
            let hoursString = hours.description
            let minutesString = minutes.description
            let format = WMFLocalizedString(
                "activity-tab-hours-minutes-read",
                value: "%1$@h %2$@m",
                comment: "Activity tab header, $1 is the amount of hours they spent reading, h is for the first letter of Hours, $2 is the amount of minutes they spent reading, m is for the first letter of Minutes."
            )
            return String.localizedStringWithFormat(format, hoursString, minutesString)
        }

        let articlesRead = WMFLocalizedString("activity-tab-articles-read", value: "Articles read this month", comment: "Title for module about articles read this month, displayed below the time spent reading this week")

        let articlesReadGraph = WMFLocalizedString("activity-tab-articles-read-graph-label", value: "Articles", comment: "Activity tab articles read graph axis label")
        let weekGraph = WMFLocalizedString("activity-tab-week-graph-label", value: "Week", comment: "Activity tab week graph axis label")

        let topCategories = WMFLocalizedString("activity-tab-top-categories", value: "Top categories this month", comment: "Title for module about top categories this month")
        let saved = WMFLocalizedString("activity-tab-saved", value: "Articles saved this month", comment: "Title for module about saved articles")

        func remaining(amount: Int) -> String {
            let format = WMFLocalizedString(
                "activity-tab-remaining-articles",
                value: "+%1$@",
                comment: "Activity tab saved articles amount, where $1 is replaced with the amount of excess articles saved above 3."
            )
            return String.localizedStringWithFormat(format, String(amount))
        }

        let loggedOutTitle = WMFLocalizedString("activity-tab-logged-out-title", value: "See more reading and editing insights", comment: "Title for logged out users")
        let loggedOutSubtitle = WMFLocalizedString("activity-tab-logged-out-subtitle", value: "Log in or create an account to view your activity on the Wikipedia app.", comment: "Subtitle for logged out users")
        let openArticle = WMFLocalizedString("open-article", value: "Open article", comment: "Open article title")
        let totalEditsAcrossProjects = WMFLocalizedString("activity-tab-total-edits", value: "Total edits across projects", comment: "Text for activity tab module about global edits")

        let edited = WMFLocalizedString("edited-article", value: "Edited", comment: "Label for edited articles")
        let emptyTitleLoggedIn = WMFLocalizedString("activity-tab-empty-title", value: "Nothing to show", comment: "Title on activity tab timeline empty state.")
        let emptySubtitleLoggedIn = WMFLocalizedString("activity-tab-empty-subtitle", value: "Start reading and editing to build your history", comment: "Subtitle on activity tab timeline empty state.")
        let emptyTitleLoggedOut = CommonStrings.emptyNoHistoryTitle
        let emptySubtitleLoggedOut = CommonStrings.emptyNoHistorySubtitle
        let yourImpact = WMFLocalizedString("activity-tab-your-impact", value: "Your impact", comment: "Title for editing section in activity tab.")

        // Customize Screen
        let customizeTimeSpentReading = WMFLocalizedString("activity-tab-customize-time-spent-reading", value: "Time spent reading", comment: "Title for time spent reading")
        let customizeReadingInsights = WMFLocalizedString("activity-tab-customize-reading-insights", value: "Reading insights", comment: "Title for reading insights")
        let customizeEditingInsights = WMFLocalizedString("activity-tab-customize-editing-insights", value: "Editing insights", comment: "Title for editing insights")
        let customizeAllTimeImpact = WMFLocalizedString("activity-tab-customize-all-time-impact", value: "All time impact", comment: "Title for all time impact")
        let customizeLastInAppDonation = WMFLocalizedString("activity-tab-customize-last-in-app-donation", value: "Last in app donation", comment: "Title for last in-app donation")
        let customizeTimelineOfBehavior = WMFLocalizedString("activity-tab-customize-timeline-of-behavior", value: "Timeline of behavior", comment: "Title for timeline of behavior")
        let customizeFooter = WMFLocalizedString("activity-tab-customize-footer", value: "Reading insights are based on your app languages in settings, and editing insights are limited to your primary app language.  Insights leverage local data, with the exception of edits which are public.", comment: "Footer for customize activity tab page.")

        // Impact module
        let allTimeImpactTitle = WMFLocalizedString("activity-tab-impact-all-time-title", value: "All time impact", comment: "Title for activity tab module about all time editing impact")
        let totalEditsLabel = WMFLocalizedString("activity-tab-impact-total-edits-label", value: "total edits", comment: "Label in impact module for total edits count")


        let bestStreakValue: (Int) -> String = { count in
            let bestStreakFormat = WMFLocalizedString("activity-tab-impact-best-streak-format", value: "{{PLURAL:%1$d|%1$d day|%1$d days}}", comment: "Count in impact module for best editing streak in number of days. %1$d is replaced with number of days.")

            return String.localizedStringWithFormat(bestStreakFormat, count)
        }

        let bestStreakLabel = WMFLocalizedString("activity-tab-impact-best-streak-label", value: "best streak", comment: "Label in impact module for best streak day count")

        let thanksLabel = WMFLocalizedString("activity-tab-impact-thanks-label", value: "thanks", comment: "Label in impact module for thanks count")
        let lastEditedLabel = WMFLocalizedString("activity-tab-impact-last-edited-label", value: "last edited", comment: "Label in impact module for last edited date")


        let yourRecentActivityTitle = WMFLocalizedString("activity-tab-impact-recent-activity-title", value: "Your recent activity (last 30 days)", comment: "Title for activity tab module about your recent editing activity")
        let editsLabel = WMFLocalizedString("activity-tab-impact-edits-label", value: "edits", comment: "Label in impact module for recent activity edit count")

        let startEndDatesAccessibilityLabel: (String, String) -> String = { startDate, endDate in
            let startEndDatesAccessibilityFormat = WMFLocalizedString("activity-tab-impact-recent-startend-accessibility", value: "From %1$@ to %2$@", comment: "Accessibility label in impact module for start / end date recent activity. %1$@ is replaced with start date, %2$@ is replaced with end date.")

            return String.localizedStringWithFormat(startEndDatesAccessibilityFormat, startDate, endDate)
        }

        let viewsOnArticlesYouveEditedTitle = WMFLocalizedString("activity-tab-impact-views-title", value: "Views on articles you’ve edited", comment: "Title for activity tab module about views on articles user edited")

        let lineGraphDay = WMFLocalizedString("activity-tab-impact-views-day", value: "Day", comment: "Accessibility label for activity tab views line graph, y-axis.")

        let lineGraphViews = WMFLocalizedString("activity-tab-impact-views-views", value: "Views", comment: "Accessibility label for activity tab views line graph, x-axis.")


        func customizeEmptyState() -> String {
            // Fake link because it's needed
            let openingLink = "<a href=\"www.wikipedia.org\">"
            let closingLink = "</a>"
            let format = WMFLocalizedString("activity-tab-customize-empty-state", value: "Activity modules are turned off. %1$@Switch them on%2$@ to see updates in this tab.", comment: "Empty state for customization on activity tab, $1 is the opening link, $2 is the closing.")
            return String.localizedStringWithFormat(format, openingLink, closingLink)
        }

        var authdValue: LoginState = .loggedOut
        if dataStore.authenticationManager.authStateIsPermanent {
            authdValue = .loggedIn
        } else if dataStore.authenticationManager.authStateIsTemporary {
            authdValue = .temp
        } else {
            authdValue = .loggedOut
        }

        let viewModel = WMFActivityTabViewModel(
            localizedStrings:
                WMFActivityTabViewModel.LocalizedStrings(
                    userNamesReading: usernamesReading(username:),
                    noUsernameReading: noUsernameReading,
                    totalHoursMinutesRead: hoursMinutesRead(hours:minutes:),
                    onWikipediaiOS: onWikipediaiOS,
                    timeSpentReading: timeSpentReading,
                    totalArticlesRead: articlesRead,
                    week: weekGraph,
                    articlesRead: articlesReadGraph,
                    topCategories: topCategories,
                    articlesSavedTitle: saved,
                    remaining: remaining(amount:),
                    loggedOutTitle: loggedOutTitle,
                    loggedOutSubtitle: loggedOutSubtitle,
                    loggedOutPrimaryCTA: CommonStrings.joinLoginTitle,
                    yourImpact: yourImpact,
                    todayTitle: CommonStrings.todayTitle,
                    yesterdayTitle: CommonStrings.yesterdayTitle,
                    openArticle: openArticle,
                    deleteAccessibilityLabel: CommonStrings.deleteActionTitle,
                    totalEditsAcrossProjects: totalEditsAcrossProjects,
                    read: CommonStrings.readString,
                    edited: edited,
                    saved: CommonStrings.shortSavedTitle,
                    emptyViewTitleLoggedIn: emptyTitleLoggedIn,
                    emptyViewSubtitleLoggedIn: emptySubtitleLoggedIn,
                    emptyViewTitleLoggedOut: emptyTitleLoggedOut,
                    emptyViewSubtitleLoggedOut: emptySubtitleLoggedOut,
                    customizeTimeSpentReading: customizeTimeSpentReading,
                    customizeReadingInsights: customizeReadingInsights,
                    customizeEditingInsights: customizeEditingInsights,
                    customizeAllTimeImpact: customizeAllTimeImpact,
                    customizeLastInAppDonation: customizeLastInAppDonation,
                    customizeTimelineOfBehavior: customizeTimelineOfBehavior,
                    customizeFooter: customizeFooter,
                    customizeEmptyState: customizeEmptyState(),
                    viewChanges: WMFLocalizedString("view-changes", value: "View changes", comment: "View changes button title"),
                    contributionsThisMonth: WMFLocalizedString("contributions-this-month", value: "Contributions this month", comment: "Title for section of contributions this month"),
                    thisMonth: WMFLocalizedString("edits-this-month", value: "edits this month", comment: "Title for edits this month section"),
                    lastMonth: WMFLocalizedString("edits-last-month", value: "edits last month", comment: "Title for edits last month section"),
                    lookingForSomethingNew: WMFLocalizedString("looking-for-something-new", value: "Looking for something new to read?", comment: "Title prompting user to explore Wikipedia"),
                    exploreWikipedia: WMFLocalizedString("explore-wikipedia", value: "Explore Wikipedia", comment: "Button title to explore Wikipedia"),
                    zeroEditsToArticles: WMFLocalizedString("zero-edits-to-articles", value: "0 edits to articles recently", comment: "Message showing zero recent edits"),
                    looksLikeYouHaventMadeAnEdit: WMFLocalizedString("looks-like-you-havent-made-an-edit", value: "Looks like you haven't made an edit this month. Extend free knowledge by editing topics that matter most to you.", comment: "Message encouraging user to make their first edit"),
                    makeAnEdit: WMFLocalizedString("learn-about-editing", value: "Learn about editing", comment: "Button title to learn about editing"),
                    viewsString: viewsString(views:),
                    mostViewed: WMFLocalizedString("activity-tab-most-viewed", value: "Most viewed since your edit", comment: "Title for section for most viewed articles since an edit"),
                    allTimeImpactTitle: allTimeImpactTitle,
                    totalEditsLabel: totalEditsLabel,
                    bestStreakValue: bestStreakValue,
                    bestStreakLabel: bestStreakLabel,
                    thanksLabel: thanksLabel,
                    lastEditedLabel: lastEditedLabel,
                    yourRecentActivityTitle: yourRecentActivityTitle,
                    editsLabel: editsLabel,
                    startEndDatesAccessibilityLabel: startEndDatesAccessibilityLabel,
                    viewsOnArticlesYouveEditedTitle: viewsOnArticlesYouveEditedTitle,
                    lineGraphDay: lineGraphDay,
                    lineGraphViews: lineGraphViews,
                    historyCalloutTitle: CommonStrings.historyMovedToSearchTitle,
                    historyCalloutBodyLoggedIn: CommonStrings.historyMovedToSearchSubtitleLoggedIn,
                    historyCalloutBodyLoggedOut: CommonStrings.historyMovedToSearchSubtitleLoggedOut,
                    calloutCloseButtonAccesibilityHint: WMFLocalizedString("activity-tab-hitory-callout-close", value: "Close history notice card", comment: "Accesibility label for close button in callout about history moving to search")
                ),
                dataController: activityTabDataController,
                authenticationState: authdValue)


        let controller = WMFActivityTabViewController(
            dataStore: dataStore,
            theme: theme,
            viewModel: viewModel,
            dataController: activityTabDataController
        )

        func viewsString(views: Int) -> String {
            let format = WMFLocalizedString("activity-tab-amount-article-views", value: "{{PLURAL:%1$d|%1$d view|%1$d views}}", comment: "$1 is the amount of views that an article has had since a user has edited it.")
            return String.localizedStringWithFormat(format, views)
        }

        return controller
    }

    func logTabBarSelectionsForActivityTab(currentTabSelection: UIViewController, newTabSelection: UIViewController) {
        guard let currentNavVC = currentTabSelection as? UINavigationController,
              currentNavVC.viewControllers.count > 0,
              let newTabNavVC = newTabSelection as? UINavigationController,
              newTabNavVC.viewControllers.count > 0 else {
            return
        }

        guard let currentVC = currentNavVC.viewControllers.last else {
            return
        }

        let newVC = newTabNavVC.viewControllers[0]

        var action: ActivityTabFunnel.Action? = nil
        if newVC is WMFActivityTabViewController {
            action = .activityNavClick
        }

        guard let action else { return }

        if currentVC is ExploreViewController {
            ActivityTabFunnel.shared.logTabBarSelected(from: .feed, action: action)
        } else if currentVC is PlacesViewController {
            ActivityTabFunnel.shared.logTabBarSelected(from: .places, action: action)
        } else if currentVC is WMFSavedHostingController {
            ActivityTabFunnel.shared.logTabBarSelected(from: .saved, action: action)
        } else if currentVC is WMFActivityTabViewController {
            ActivityTabFunnel.shared.logTabBarSelected(from: .activityTab, action: action)
        } else if currentVC is SearchViewController {
            ActivityTabFunnel.shared.logTabBarSelected(from: .search, action: action)
        } else if currentVC is SettingsTabViewController {
            ActivityTabFunnel.shared.logTabBarSelected(from: .settings, action: action)
        } else if let article = currentVC as? ArticleViewController {
            guard let title = article.articleURL.wmf_title?.denormalizedPageTitle else {
                return
            }

            if title == "Main_Page" {
                ActivityTabFunnel.shared.logTabBarSelected(from: .mainPage, action: action)
            } else {
                ActivityTabFunnel.shared.logTabBarSelected(from: .article, action: action)
            }
        }
    }
}

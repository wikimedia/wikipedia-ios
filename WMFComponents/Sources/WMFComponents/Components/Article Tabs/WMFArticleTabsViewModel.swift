import Foundation
import SwiftUI
import WMFData

@MainActor
public protocol WMFArticleTabsLoggingDelegate: AnyObject {
    func logArticleTabsOverviewImpression()
    func logArticleTabsArticleClick(wmfProject: WMFProject?)
    func logArticleTabsOverviewTappedDone()
    func logArticleTabsOverviewTappedCloseTab()
    func logArticleTabsOverviewTappedHideSuggestions()
    func logArticleTabsOverviewTappedShowSuggestions()
    func logArticleTabsOverviewTappedCloseAllTabs()
    func logArticleTabsOverviewTappedCloseAllTabsConfirmCancel()
    func logArticleTabsOverviewTappedCloseAllTabsConfirmClose()
}

public class WMFArticleTabsViewModel: NSObject, ObservableObject {
    // articleTab should NEVER be empty - take care of logic of inserting main page in datacontroller/viewcontroller
    @Published var articleTabs: [ArticleTab] = [] {
        didSet {
            Task { @MainActor in
                updateHasMultipleTabs()
            }
        }
    }
    @Published var shouldShowCloseButton: Bool
    @Published public var hasMultipleTabs: Bool = false
    @Published var currentTabID: String?

    let shouldShowCurrentTabBorder: Bool

    private(set) weak var loggingDelegate: WMFArticleTabsLoggingDelegate?
    private let dataController: WMFArticleTabsDataController
    public var updateNavigationBarTitleAction: ((Int) -> Void)?

    public let didTapTab: (WMFArticleTabsDataController.WMFArticleTab) -> Void
    public let didTapAddTab: () -> Void
    public let didTapShareTab: (WMFArticleTabsDataController.WMFArticleTab, CGRect?) -> Void
    public let didTapDone: () -> Void
    public let didToggleSuggestedArticles: () -> Void

    public let localizedStrings: LocalizedStrings
    
    public init(dataController: WMFArticleTabsDataController,
                localizedStrings: LocalizedStrings,
                loggingDelegate: WMFArticleTabsLoggingDelegate?,
                didTapTab: @escaping (WMFArticleTabsDataController.WMFArticleTab) -> Void,
                didTapAddTab: @escaping () -> Void,
                didTapShareTab: @escaping (WMFArticleTabsDataController.WMFArticleTab, CGRect?) -> Void,
                didTapDone: @escaping () -> Void,
                didToggleSuggestedArticles: @escaping () -> Void) {
        self.dataController = dataController
        self.localizedStrings = localizedStrings
        self.loggingDelegate = loggingDelegate
        self.articleTabs = []
        self.shouldShowCloseButton = false
        self.shouldShowCurrentTabBorder = dataController.shouldShowMoreDynamicTabsV2
        self.didTapTab = didTapTab
        self.didTapAddTab = didTapAddTab
        self.didTapShareTab = didTapShareTab
        self.didTapDone = didTapDone
        self.didToggleSuggestedArticles = didToggleSuggestedArticles
        super.init()
        Task {
            await loadTabs()
        }
        updateShouldShowSuggestions()
    }
    
    public func didTapCloseAllTabs() {
        Task {
            try? await dataController.deleteAllTabs()
            Task { @MainActor in
                await loadTabs()
            }
        }
    }
    
    @Published public var shouldShowSuggestions: Bool = false
    
    private func updateShouldShowSuggestions() {
        shouldShowSuggestions = dataController.shouldShowMoreDynamicTabsV2 &&
        !dataController.userHasHiddenArticleSuggestionsTabs
    }
    
    public func refreshShouldShowSuggestionsFromDataController() {
        updateShouldShowSuggestions()
    }
    
    @MainActor
    private func updateHasMultipleTabs() {
        var count = 0
        if articleTabs.isEmpty {
            hasMultipleTabs = false
            return
        }
        for tab in articleTabs where !tab.isMain {
            count += 1
            if count >= 2 {
                hasMultipleTabs = true
                return
            }
        }
        hasMultipleTabs = false
    }
    
    public struct LocalizedStrings {
        public let navBarTitleFormat: String
        public let mainPageTitle: String?
        public let mainPageSubtitle: String
        public let mainPageDescription: String
        public let closeTabAccessibility: String
        public let openTabAccessibility: String
        public let shareTabButtonTitle: String
        public let closeAllTabs: String
        public let cancelActionTitle: String
        public let closeAllTabsTitle: (Int) -> String
        public let closeAllTabsSubtitle: (Int) -> String
        public let closedAlertsNotification: String
        public let hideSuggestedArticlesTitle: String
        public let showSuggestedArticlesTitle: String
        public let emptyStateTitle: String
        public let emptyStateSubtitle: String

        public init(navBarTitleFormat: String, mainPageTitle: String?, mainPageSubtitle: String, mainPageDescription: String, closeTabAccessibility: String, openTabAccessibility: String, shareTabButtonTitle: String, closeAllTabs: String, cancelActionTitle: String, closeAllTabsTitle: @escaping (Int) -> String, closeAllTabsSubtitle: @escaping (Int) -> String, closedAlertsNotification: String, hideSuggestedArticlesTitle: String, showSuggestedArticlesTitle: String, emptyStateTitle: String, emptyStateSubtitle: String) {
            self.navBarTitleFormat = navBarTitleFormat
            self.mainPageTitle = mainPageTitle
            self.mainPageSubtitle = mainPageSubtitle
            self.mainPageDescription = mainPageDescription
            self.closeTabAccessibility = closeTabAccessibility
            self.openTabAccessibility = openTabAccessibility
            self.shareTabButtonTitle = shareTabButtonTitle
            self.closeAllTabs = closeAllTabs
            self.cancelActionTitle = cancelActionTitle
            self.closeAllTabsTitle = closeAllTabsTitle
            self.closeAllTabsSubtitle = closeAllTabsSubtitle
            self.closedAlertsNotification = closedAlertsNotification
            self.hideSuggestedArticlesTitle = hideSuggestedArticlesTitle
            self.showSuggestedArticlesTitle = showSuggestedArticlesTitle
            self.emptyStateTitle = emptyStateTitle
            self.emptyStateSubtitle = emptyStateSubtitle
        }
    }
    
    @MainActor
    private func loadTabs() async {
        do {
            let tabs = try await dataController.fetchAllArticleTabs()
            articleTabs = tabs.map { tab in
                ArticleTab(
                    title: tab.articles.last?.title.underscoresToSpaces ?? "",
                    dateCreated: tab.timestamp,
                    info: nil,
                    data: tab
                )
            }
            updateHasMultipleTabs()
            await refreshCurrentTab()
            updateNavigationBarTitleAction?(articleTabs.count)

            if dataController.shouldShowMoreDynamicTabsV2 {
                shouldShowCloseButton = true
            } else {
                shouldShowCloseButton = articleTabs.count > 1
            }

        } catch {
            // Handle error appropriately
            debugPrint("Error loading tabs: \(error)")
        }
    }

    // MARK: - Public funcs
    
    @MainActor
    func refreshCurrentTab() async {
        do {
            let tabUUID = try await dataController.currentTabIdentifier()
            currentTabID = tabUUID?.uuidString
        } catch {
            print("Not able to get tab UUID")
        }
    }
    
    @MainActor
    func shouldLockAspectRatio() -> Bool {
        if UIApplication.shared.preferredContentSizeCategory.isAccessibilityCategory {
            return false
        }
        return true
    }
    
    func calculateColumns(for size: CGSize) -> Int {
        // If text is scaled up for accessibility, use single column
        if UIApplication.shared.preferredContentSizeCategory.isAccessibilityCategory {
            return 1
        }

        let isPortrait = size.height > size.width
        let isPad = UIDevice.current.userInterfaceIdiom == .pad

        if isPortrait {
            if isPad {
                // Reduce number of columns on iPad mini screen to preserve 3/4 aspect ratio
                if size.width <= 744.0 {
                    return 3
                } else {
                    return 4
                }
            } else {
                return 2
            }
        } else {
            return 4
        }
    }
    
    func description(for tab: ArticleTab) -> String? {
        guard let description = tab.info?.description else { return nil }
        return description.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func calculateImageHeight(horizontalSizeClass: UserInterfaceSizeClass?) -> Int {
        if UIApplication.shared.preferredContentSizeCategory.isAccessibilityCategory {
            if UIDevice.current.userInterfaceIdiom == .pad {
                return 425
            }
            return 225
        }
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            guard let horizontalSizeClass else { return 110 }
            let isLandscape = horizontalSizeClass == .regular
            return isLandscape ? 160 : 110
        }

        return 95
    }
    
    func getAccessibilityLabel(for tab: ArticleTab) -> String {
        var label = ""
        if tab.isMain {
            label += tab.title
            label += " " + localizedStrings.mainPageSubtitle
        } else {
            label += tab.title
            if let subtitle = tab.info?.subtitle {
                label += " " + subtitle
            }
        }
        
        return label
    }
    
    func closeTab(tab: ArticleTab) {
        
        Task {
            do {
                try await dataController.deleteArticleTab(identifier: tab.data.identifier)
                
                Task { @MainActor [weak self]  in
                    guard let self else { return }
                    loggingDelegate?.logArticleTabsOverviewTappedCloseTab()
                    articleTabs.removeAll { $0 == tab }
                    updateHasMultipleTabs()
                    if dataController.shouldShowMoreDynamicTabsV2 {
                        shouldShowCloseButton = true
                    }
                    await refreshCurrentTab()
                    updateNavigationBarTitleAction?(articleTabs.count)
                }
                
            } catch {
                debugPrint("Error closing tab: \(error)")
            }
        }
    }

    var shouldShowTabsV2: Bool {
        return dataController.shouldShowMoreDynamicTabsV2
    }

    // MARK: - Populate article summary

    @MainActor private var incomingTabIDs = Set<String>()
    @MainActor private var prefetchedTabIDs = Set<String>()

    /// Kick off a prefetch immediately for the visible window of 24 tabs, then trickle the rest in the background
    func prefetchAllSummariesTrickled(initialWindow: Int = 24,
                                      pageSize: Int = 12,
                                      delayBetweenBatchesNs: UInt64 = 150_000_000) {
        let tabsSnapshot = articleTabs
        let mainSubtitle = localizedStrings.mainPageSubtitle
        let mainDescription = localizedStrings.mainPageDescription

        Task { [weak self] in
            guard let self else { return }
            await self.prefetchBatch(
                for: Array(tabsSnapshot.prefix(initialWindow)),
                mainSubtitle: mainSubtitle,
                mainDescription: mainDescription
            )
        }

        // Background fetch remainder of tabs
        Task.detached(priority: .background) { [weak self] in
            guard let self else { return }
            var remainder = Array(tabsSnapshot.dropFirst(initialWindow))

            while !remainder.isEmpty {
                let chunk = Array(remainder.prefix(pageSize))
                await self.prefetchBatch(
                    for: chunk,
                    mainSubtitle: mainSubtitle,
                    mainDescription: mainDescription
                )
                remainder.removeFirst(min(pageSize, remainder.count))
                try? await Task.sleep(nanoseconds: delayBetweenBatchesNs)
            }
        }
    }

    /// Prefetch tabs snapshot info for thumbs and previews
    private func prefetchBatch(for tabs: [ArticleTab], mainSubtitle: String, mainDescription: String) async {

        struct Input: Sendable {
            let id: String
            let project: WMFProject
            let title: String
            let url: URL?
            let isMain: Bool
        }

        let inputs: [Input] = await MainActor.run { [weak self] in
            guard let self else { return [] }
            return tabs.compactMap { tab -> Input? in
                // Check prefetched items
                if self.prefetchedTabIDs.contains(tab.id) || self.incomingTabIDs.contains(tab.id) { return nil }
                guard let last = tab.data.articles.last else { return nil }
                self.incomingTabIDs.insert(tab.id)
                return Input(id: tab.id, project: last.project, title: last.title, url: last.articleURL, isMain: last.isMain)
            }
        }

        guard !inputs.isEmpty else { return }

        await withTaskGroup(of: (id: String, info: ArticleTab.Info?).self) { group in
            for input in inputs {
                group.addTask {
                    do {
                        let dc = WMFArticleSummaryDataController.shared
                        let summary = try await dc.fetchArticleSummary(project: input.project, title: input.title)

                        let subtitle = input.isMain ? mainSubtitle     : summary.description
                        let desc     = input.isMain ? mainDescription  : summary.extract

                        let info = ArticleTab.Info(
                            subtitle: subtitle,
                            image: summary.thumbnailURL,
                            description: desc,
                            url: input.url,
                            snippet: desc
                        )
                        return (input.id, info)
                    } catch {
                        return (input.id, nil)
                    }
                }
            }

            for await (id, info) in group {
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    self.incomingTabIDs.remove(id)
                    self.prefetchedTabIDs.insert(id)
                    if let idx = self.articleTabs.firstIndex(where: { $0.id == id }),
                       self.articleTabs[idx].info == nil {
                        self.articleTabs[idx].info = info
                    }
                }
            }
        }
    }

    /// One-off fetch (newly visible cells or newly created tabs)
    @MainActor
    func ensureInfo(for tab: ArticleTab) async {
        guard tab.info == nil, let last = tab.data.articles.last else { return }

        if incomingTabIDs.contains(tab.id) || prefetchedTabIDs.contains(tab.id) { return }

        incomingTabIDs.insert(tab.id)
        Task.detached(priority: .utility) { [weak self] in
            guard let self else { return }
            defer { Task { @MainActor in self.incomingTabIDs.remove(tab.id) } }
            do {
                let dc = WMFArticleSummaryDataController.shared
                let summary = try await dc.fetchArticleSummary(project: last.project, title: last.title)
                let subtitle = last.isMain ? self.localizedStrings.mainPageSubtitle : summary.description
                let snippet = last.isMain ? self.localizedStrings.mainPageDescription : summary.extract
                let info = ArticleTab.Info(
                    subtitle: subtitle,
                    image: summary.thumbnailURL,
                    description: snippet,
                    url: last.articleURL,
                    snippet: snippet
                )
                await MainActor.run {
                    if tab.info == nil { tab.info = info }
                    self.prefetchedTabIDs.insert(tab.id)
                }
            } catch {
                print( "Unable to fetch article summary: \(error)")
            }
        }
    }

    func getCurrentTab() async -> ArticleTab? {
        do {
            guard let tabUUID = try await dataController.currentTabIdentifier() else {
                return nil
            }

            if let tab = articleTabs.first(where: {$0.id == tabUUID.uuidString}) {
                return tab

            }
        } catch {
            print("Not able to get tab UUID")
        }

        return articleTabs.first
    }
}

class ArticleTab: Identifiable, Hashable, Equatable, ObservableObject {
    
    struct Info {
        let subtitle: String?
        let image: URL?
        let description: String?
        let url: URL?
        let snippet: String?
    }

    let title: String
    @Published var info: Info?
    
    let dateCreated: Date
    let data: WMFArticleTabsDataController.WMFArticleTab

    init(title: String, dateCreated: Date, info: Info?, data: WMFArticleTabsDataController.WMFArticleTab) {
        self.title = title
        self.info = info
        self.dateCreated = dateCreated
        self.data = data
    }
    
    var id: String {
        return data.identifier.uuidString
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func ==(lhs: ArticleTab, rhs: ArticleTab) -> Bool {
        return lhs.id == rhs.id
    }
    
    var isMain: Bool {
        return data.articles.last?.isMain ?? false
    }
}

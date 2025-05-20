import Foundation
import SwiftUI
import WMFData

public class WMFArticleTabsViewModel: NSObject, ObservableObject {
    // articleTab should NEVER be empty - take care of logic of inserting main page in datacontroller/viewcontroller
    @Published var articleTabs: [ArticleTab]
    @Published var shouldShowCloseButton: Bool
    @Published var count: Int
    
    private let dataController: WMFArticleTabsDataController
    public var onTabCountChanged: ((Int) -> Void)?
    public var updateNavigationBarTitleAction: ((Int) -> Void)?

    public let didTapTab: (WMFArticleTabsDataController.WMFArticleTab) -> Void
    public let didTapAddTab: () -> Void
    public let populateSummary: @Sendable (WMFArticleTabsDataController.WMFArticleTab) async -> WMFArticleTabsDataController.WMFArticleTab
    
    public let localizedStrings: LocalizedStrings
    
    public init(dataController: WMFArticleTabsDataController,
                localizedStrings: LocalizedStrings,
                didTapTab: @escaping (WMFArticleTabsDataController.WMFArticleTab) -> Void,
                didTapAddTab: @escaping () -> Void,
                populateSummary: @escaping @Sendable (WMFArticleTabsDataController.WMFArticleTab) async -> WMFArticleTabsDataController.WMFArticleTab) {
        self.dataController = dataController
        self.localizedStrings = localizedStrings
        self.articleTabs = []
        self.shouldShowCloseButton = false
        self.count = 0
        self.didTapTab = didTapTab
        self.didTapAddTab = didTapAddTab
        self.populateSummary = populateSummary
        super.init()
        Task {
            await loadTabs()
        }
    }
    
    public struct LocalizedStrings {
        public let navBarTitleFormat: String
        public let mainPageSubtitle: String
        public let mainPageDescription: String
        public let closeTabAccessibility: String
        public let openTabAccessibility: String
        
        public init(navBarTitleFormat: String, mainPageSubtitle: String, mainPageDescription: String, closeTabAccessibility: String, openTabAccessibility: String) {
            self.navBarTitleFormat = navBarTitleFormat
            self.mainPageSubtitle = mainPageSubtitle
            self.mainPageDescription = mainPageDescription
            self.closeTabAccessibility = closeTabAccessibility
            self.openTabAccessibility = openTabAccessibility
        }
    }
    
    @MainActor
    private func loadTabs() async {
        do {
            let tabs = try await dataController.fetchAllArticleTabs()
            // let populatedTabs = await populateSummaries(tabs)
            self.articleTabs = tabs.map { tab in
                ArticleTab(
                    image: tab.articles.last?.imageURL,
                    title: tab.articles.last?.title.underscoresToSpaces ?? "",
                    subtitle: tab.articles.last?.description,
                    description: tab.articles.last?.summary,
                    dateCreated: tab.timestamp,
                    data: tab,
                    isLoading: true
                )
            }
            self.shouldShowCloseButton = articleTabs.count > 1
            self.count = articleTabs.count
            onTabCountChanged?(count)
            updateNavigationBarTitleAction?(count)
        } catch {
            // Handle error appropriately
            print("Error loading tabs: \(error)")
        }
    }
    
    // MARK: - Public funcs

    public func calculateColumns(for size: CGSize) -> Int {
        // If text is scaled up for accessibility, use single column
        if UIApplication.shared.preferredContentSizeCategory.isAccessibilityCategory {
            return 1
        }

        let isPortrait = size.height > size.width
        let isPad = UIDevice.current.userInterfaceIdiom == .pad

        if isPortrait {
            return isPad ? 4 : 2
        } else {
            return 4
        }
    }
    
    public func calculateImageHeight() -> Int {
        // If text is scaled up for accessibility, use taller image for single column
        if UIApplication.shared.preferredContentSizeCategory.isAccessibilityCategory {
            return 225
        }
        return 95
    }
    
    public func getAccessibilityLabel(for tab: ArticleTab) -> String {
        var label = ""
        if tab.isMain {
            label += tab.title
            label += " " + localizedStrings.mainPageSubtitle
        } else {
            label += tab.title
            if let subtitle = tab.subtitle {
                label += " " + subtitle
            }
        }
        
        return label
    }
    
    public func closeTab(tab: ArticleTab) {
        Task {
            do {
                try await dataController.deleteArticleTab(identifier: tab.data.identifier)
                await loadTabs()
            } catch {
                print("Error closing tab: \(error)")
            }
        }
    }
    
    public func tabsCount() async throws -> Int {
        return try await dataController.tabsCount()
    }
}

public class ArticleTab: Identifiable, ObservableObject {
    @Published var image: URL?
    @Published var title: String
    @Published var subtitle: String?
    @Published var description: String?
    let dateCreated: Date
    let data: WMFArticleTabsDataController.WMFArticleTab
    @Published var isLoading: Bool

    public init(image: URL?, title: String, subtitle: String?, description: String?, dateCreated: Date, data: WMFArticleTabsDataController.WMFArticleTab, isLoading: Bool) {
        self.image = image
        self.title = title
        self.subtitle = subtitle
        self.description = description
        self.dateCreated = dateCreated
        self.data = data
        self.isLoading = isLoading
    }
    
    public var id: String {
        return data.identifier.uuidString
    }
    
    var isMain: Bool {
        return data.articles.last?.isMain ?? false
    }
    
    func update(image: URL?, title: String, subtitle: String?, description: String?) {
        self.image = image
        self.title = title
        self.subtitle = subtitle
        self.description = description
    }
}

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
    public let didTapMainTab: () -> Void
    
    public let localizedStrings: LocalizedStrings
    
    public init(dataController: WMFArticleTabsDataController,
                localizedStrings: LocalizedStrings,
                didTapTab: @escaping (WMFArticleTabsDataController.WMFArticleTab) -> Void,
                didTapAddTab: @escaping () -> Void,
                didTapMainTab: @escaping () -> Void) {
        self.dataController = dataController
        self.localizedStrings = localizedStrings
        self.articleTabs = []
        self.shouldShowCloseButton = false
        self.count = 0
        self.didTapTab = didTapTab
        self.didTapAddTab = didTapAddTab
        self.didTapMainTab = didTapMainTab
        super.init()
        Task {
            await loadTabs()
        }
    }
    
    public struct LocalizedStrings {
        public let navBarTitleFormat: String
        
        public init(navBarTitleFormat: String) {
            self.navBarTitleFormat = navBarTitleFormat
        }
    }
    
    @MainActor
    private func loadTabs() async {
        do {
            let tabs = try await dataController.fetchAllArticleTabs()
            self.articleTabs = tabs.map { tab in
                ArticleTab(
                    id: tab.identifier,
                    image: tab.articles.last?.imageURL,
                    title: tab.articles.last?.title.underscoresToSpaces ?? "",
                    subtitle: tab.articles.last?.description,
                    description: tab.articles.last?.summary,
                    dateCreated: tab.timestamp,
                    onTapOpen: nil,
                    project: tab.articles.last?.project,
                    dataTab: tab
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
    
    public func closeTab(tab: ArticleTab) {
        Task {
            do {
                try await dataController.deleteArticleTab(identifier: tab.id)
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

public struct ArticleTab: Identifiable {
    public var id = UUID()
    let image: URL?
    let title: String
    let subtitle: String?
    let description: String?
    let dateCreated: Date
    let onTapOpen: (() -> Void)?
    let project: WMFProject?
    let dataTab: WMFArticleTabsDataController.WMFArticleTab? // todo: gross, clean up

    public init(id: UUID = UUID(), image: URL?, title: String, subtitle: String?, description: String?, dateCreated: Date, onTapOpen: (() -> Void)? = nil, project: WMFProject? = nil, dataTab: WMFArticleTabsDataController.WMFArticleTab?) {
        self.id = id
        self.image = image
        self.title = title
        self.subtitle = subtitle
        self.description = description
        self.dateCreated = dateCreated
        self.onTapOpen = onTapOpen
        self.project = project
        self.dataTab = dataTab
    }
}

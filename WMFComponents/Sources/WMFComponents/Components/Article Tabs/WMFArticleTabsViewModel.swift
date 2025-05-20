import Foundation
import SwiftUI
import WMFData

public class WMFArticleTabsViewModel: NSObject, ObservableObject {
    // articleTab should NEVER be empty - take care of logic of inserting main page in datacontroller/viewcontroller
    @Published var articleTabs: [ArticleTab]
    @Published var shouldShowCloseButton: Bool
    
    private let dataController: WMFArticleTabsDataController
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
            articleTabs = tabs.map { tab in
                ArticleTab(
                    title: tab.articles.last?.title.underscoresToSpaces ?? "",
                    dateCreated: tab.timestamp,
                    info: nil,
                    data: tab
                )
            }
            shouldShowCloseButton = articleTabs.count > 1
            updateNavigationBarTitleAction?(articleTabs.count)
        } catch {
            // Handle error appropriately
            debugPrint("Error loading tabs: \(error)")
        }
    }
    
    // MARK: - Public funcs

    func calculateColumns(for size: CGSize) -> Int {
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
    
    func calculateImageHeight() -> Int {
        // If text is scaled up for accessibility, use taller image for single column
        if UIApplication.shared.preferredContentSizeCategory.isAccessibilityCategory {
            return 225
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
                    articleTabs.removeAll { $0 == tab }
                    shouldShowCloseButton = articleTabs.count > 1
                    updateNavigationBarTitleAction?(articleTabs.count)
                }
                
            } catch {
                debugPrint("Error closing tab: \(error)")
            }
        }
    }
}

class ArticleTab: Identifiable, Hashable, Equatable, ObservableObject {
    
    struct Info {
        let subtitle: String?
        let image: URL?
        let description: String?
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

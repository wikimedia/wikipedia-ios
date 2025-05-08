import Foundation
import SwiftUI
import WMFData

public class WMFArticleTabsViewModel: NSObject, ObservableObject {
    // articleTab should NEVER be empty - take care of logic of inserting main page in datacontroller/viewcontroller
    @Published var articleTabs: [ArticleTab]
    @Published var shouldShowCloseButton: Bool
    @Published var count: Int
    
    public init(articleTabs: [ArticleTab]) {
        self.articleTabs = articleTabs
        self.shouldShowCloseButton = articleTabs.count > 1
        self.count = articleTabs.count
    }
    
    
    // MARK: - Public funcs

    public func calculateColumns(for size: CGSize) -> Int {
        let isPortrait = size.height > size.width
        let isPad = UIDevice.current.userInterfaceIdiom == .pad

        if isPortrait {
            return isPad ? 4 : 2
        } else {
            return 4
        }
    }
    
    public func closeTab(tab: ArticleTab) {
        if let index = articleTabs.firstIndex(where: { $0.id == tab.id }) {
            articleTabs.remove(at: index)
        }
        updateArticleTabs()
    }
    
    public func addTab() {
        // TODO
        updateArticleTabs()
    }
    
    // MARK: - Helper funcs
    
    private func updateArticleTabs() {
        shouldShowCloseButton = articleTabs.count > 1
        count = articleTabs.count
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

    public init(id: UUID = UUID(), image: URL?, title: String, subtitle: String?, description: String?, dateCreated: Date, onTapOpen: (() -> Void)? = nil, project: WMFProject? = nil) {
        self.id = id
        self.image = image
        self.title = title
        self.subtitle = subtitle
        self.description = description
        self.dateCreated = dateCreated
        self.onTapOpen = onTapOpen
        self.project = project
    }
}

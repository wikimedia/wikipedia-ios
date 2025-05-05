import Foundation
import SwiftUI
import WMFData

public class WMFArticleTabsViewModel: NSObject, ObservableObject {
    @Published var articleTabs: [ArticleTab] = []
    @Published var shouldShowCloseButton: Bool
    
    public init(articleTabs: [ArticleTab]) {
        self.articleTabs = articleTabs
        self.shouldShowCloseButton = !(articleTabs.isEmpty && articleTabs.count == 1)
    }
    
    public func calculateColumns(for size: CGSize) -> Int {
        let isPortrait = size.height > size.width
        let isPad = UIDevice.current.userInterfaceIdiom == .pad

        if isPortrait {
            return isPad ? 4 : 2
        } else {
            return 4
        }
    }
    
    public func calculateImageHeight(for size: CGSize) -> Int {
        let isPortrait = size.height > size.width
        let isPad = UIDevice.current.userInterfaceIdiom == .pad

        if isPortrait {
            return isPad ? 150 : 95
        } else {
            return 150
        }
    }
}

public struct ArticleTab: Identifiable {
    public var id = UUID()
    let image: URL?
    let title: String
    let subtitle: String?
    let description: String?
    let dateCreated: Date
    
    public init(image: URL?, title: String, subtitle: String?, description: String?, dateCreated: Date) {
        self.image = image
        self.title = title
        self.subtitle = subtitle
        self.description = description
        self.dateCreated = dateCreated
    }
}

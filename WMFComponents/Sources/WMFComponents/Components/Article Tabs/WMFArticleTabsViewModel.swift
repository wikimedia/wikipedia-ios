import Foundation
import SwiftUI
import WMFData

public class WMFArticleTabsViewModel: NSObject, ObservableObject {
    @Published var articleTabs: [ArticleTab] = []
    
    public init(articleTabs: [ArticleTab]) {
        self.articleTabs = articleTabs
    }
    
    public func calculateColumns(for size: CGSize) -> Int {
        let isPortrait = size.height > size.width
        let isPad = UIDevice.current.userInterfaceIdiom == .pad

        if isPortrait {
            return isPad ? 4 : 2
        } else {
            return 5
        }
    }
}

public struct ArticleTab: Identifiable {
    public var id = UUID()
    let image: URL?
    let title: String
    let subtitle: String?
    let description: String?
    
    public init(image: URL?, title: String, subtitle: String?, description: String?) {
        self.image = image
        self.title = title
        self.subtitle = subtitle
        self.description = description
    }
}

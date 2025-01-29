import Foundation

struct Tab: Equatable {
    
    struct Article: Equatable {
        let id: UUID = UUID()
        let title: String
        let project: WMFProject
        
        static func == (lhs: Article, rhs: Article) -> Bool {
            return
                lhs.id == rhs.id &&
                lhs.title == rhs.title &&
                lhs.project == rhs.project
        }
    }
    
    let id: UUID = UUID()
    private(set) var articles: [Article]
    
    static func == (lhs: Tab, rhs: Tab) -> Bool {
        return lhs.articles == rhs.articles &&
            lhs.id == rhs.id
    }
    
    mutating func addArticle(article: Article) {
        articles.append(article)
    }
    
    mutating func removeArticle(article: Article) {
        articles.removeAll { $0 == article }
    }
    
}

final class TabsDataController {
   
    static let shared = TabsDataController(tabs: [])
    
    private(set) var tabs: [Tab]
    
    init(tabs: [Tab]) {
        self.tabs = tabs
    }
    
    func addTab(tab: Tab) {
        tabs.append(tab)
    }
    
    func removeTab(tab: Tab) {
        tabs.removeAll { $0 == tab }
    }
}

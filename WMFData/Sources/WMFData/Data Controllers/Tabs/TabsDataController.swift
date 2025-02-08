import Foundation

public final class Tab: Equatable {
    public final class Article: Equatable {
        public let title: String
        let project: WMFProject
        
        public static func == (lhs: Article, rhs: Article) -> Bool {
            return
                lhs.title == rhs.title &&
                lhs.project == rhs.project
        }
        
        public init(title: String, project: WMFProject) {
            self.title = title
            self.project = project
        }
    }
    
    let id: UUID = UUID()
    public private(set) var articles: [Article]
    
    public init(articles: [Tab.Article]) {
        self.articles = articles
    }
    
    public static func == (lhs: Tab, rhs: Tab) -> Bool {
        return lhs.articles == rhs.articles &&
            lhs.id == rhs.id
    }
    
    func addArticle(article: Article) {
        articles.append(article)
    }
    
    func removeLastArticle() {
        articles.removeLast()
    }
}

public final class TabsDataController {
   
    public static let shared = TabsDataController(tabs: [])
    
    public var currentTab: Tab?
    
    public private(set) var tabs: [Tab]
    
    init(tabs: [Tab]) {
        self.tabs = tabs
    }
    
    public func addArticleToCurrentTab(article: Tab.Article) {
        
        guard let currentTab else {
            let newTab = Tab(articles: [article])
            addTab(tab: newTab)
            self.currentTab = newTab
            return
        }
        
        // if article is already top of current tab, do nothing
        if let topArticle = currentTab.articles.last,
              article == topArticle {
            return
        }
        
        currentTab.addArticle(article: article)
    }
    
    public func removeLastArticleFromCurrentTab() {
        
        guard let currentTab else {
            return
        }
        
        currentTab.removeLastArticle()
        
        if currentTab.articles.count == 0 {
            removeTab(tab: currentTab)
            self.currentTab = nil
        }
    }
    
    func addTab(tab: Tab) {
        tabs.append(tab)
    }
    
    func removeTab(tab: Tab) {
        tabs.removeAll { $0 == tab }
    }
}

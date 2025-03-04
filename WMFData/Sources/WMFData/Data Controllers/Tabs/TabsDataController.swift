import Foundation

public final class Tab: Equatable {
    public final class Article: Equatable {
        public let title: String
        public let project: WMFProject
        
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
    public var currentArticleIndex: Int
    public var dateCreated: Date
    
    public init(article: WMFData.Tab.Article) {
        articles = [article]
        currentArticleIndex = 0
        dateCreated = Date()
    }
    
    public static func == (lhs: WMFData.Tab, rhs: WMFData.Tab) -> Bool {
        return lhs.articles == rhs.articles &&
            lhs.id == rhs.id
    }
    
    public func addArticle(_ article: Article) {
        
        guard articles.count > 0 else {
            articles.append(article)
            self.currentArticleIndex = 0
            return
        }
        
        let delta = (articles.count - 1) - currentArticleIndex
        if delta > 0 { // We are adding an article in the middle of a stack. We must insert it, then delete the remaining stack.
            articles.insert(article, at: currentArticleIndex + 1)
            articles.removeLast(delta)
        } else {
            articles.append(article)
        }
        
        self.currentArticleIndex = articles.count - 1
    }
    
    func back() {
        guard currentArticleIndex > 0 else {
            return
        }
        currentArticleIndex -= 1
    }
    
    func canGoForward() -> Bool {
        return currentArticleIndex < articles.count - 1
    }
    
    func forward() {
        guard currentArticleIndex > articles.count - 1 else {
            assertionFailure("Unexpected setup. Be sure to check canGoForward() before enabling a forward button.")
            return
        }
        
        currentArticleIndex += 1
    }
}

public final class TabsDataController {
   
    public static let shared = TabsDataController(tabs: [])
    
    public var currentTab: WMFData.Tab?
    
    public private(set) var tabs: [WMFData.Tab]
    
    init(tabs: [WMFData.Tab]) {
        self.tabs = tabs
    }
    
    public func addArticleToCurrentTab(article: WMFData.Tab.Article) {
        
        guard let currentTab else {
            let tab = WMFData.Tab(article: article)
            self.addTab(tab: tab)
            self.currentTab = tab
            return
        }
        
        currentTab.addArticle(article)
    }
    
    public func back(tab: WMFData.Tab) {
        tab.back()
    }
    
    public func forward(tab: WMFData.Tab) {
        tab.forward()
    }
    
    public func addTab(tab: WMFData.Tab) {
        tabs.append(tab)
    }
    
    public func removeTab(tab: WMFData.Tab) {
        tabs.removeAll { $0 == tab }
        
        if currentTab == tab {
            currentTab = nil
        }
    }
}

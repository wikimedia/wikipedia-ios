public struct NavigationState: Codable {
    static let libraryKey = "nav_state"

    public var viewControllers: [ViewController]
    public var shouldAttemptLogin: Bool

    public init(viewControllers: [ViewController], shouldAttemptLogin: Bool) {
        self.viewControllers = viewControllers
        self.shouldAttemptLogin = shouldAttemptLogin
    }
    
    public struct ViewController: Codable {
        public var kind: Kind
        public var presentation: Presentation
        public var info: Info?
        public var children: [ViewController]
        
        public mutating func updateChildren(_ children: [ViewController]) {
            self.children = children
        }
        
        public init?(kind: Kind?, presentation: Presentation, info: Info? = nil, children: [ViewController] = []) {
            guard let kind = kind else {
                return nil
            }
            self.kind = kind
            self.presentation = presentation
            self.info = info
            self.children = children
        }
        
        public enum Kind: Int, Codable {
            case tab
            
            case article
            case random
            case themeableNavigationController
            case settings
            
            case account
            case talkPage
            case talkPageReplyList
            
            case singleWebPage
            
            case readingListDetail
            
            case detail
            
            init?(from rawValue: Int?) {
                guard let rawValue = rawValue else {
                    return nil
                }
                self.init(rawValue: rawValue)
            }
        }
        
        public enum Presentation: Int, Codable {
            case push
            case modal
        }
        
        public struct Info: Codable {
            public var selectedIndex: Int?
            
            public var articleKey: String?
            public var articleSectionAnchor: String?
            
            public var talkPageSiteURLString: String?
            public var talkPageTitle: String?
            public var talkPageTypeRawValue: Int?

            public var currentSavedViewRawValue: Int?
            
            public var readingListURIString: String?
            
            public var searchTerm: String?

            public var shouldShowNavigationBar: Bool?
            
            public var contentGroupIDURIString: String?

            public var presentedContentGroupKey: String?
            
            public var url: URL?
            
            // TODO: Remove after moving to Swift 5.1 -
            // https://github.com/apple/swift-evolution/blob/master/proposals/0242-default-values-memberwise.md
            public init(url: URL? = nil, selectedIndex: Int? = nil, articleKey: String? = nil, articleSectionAnchor: String? = nil, talkPageSiteURLString: String? = nil, talkPageTitle: String? = nil, talkPageTypeRawValue: Int? = nil, currentSavedViewRawValue: Int? = nil, readingListURIString: String? = nil, searchTerm: String? = nil, shouldShowNavigationBar: Bool? = nil, contentGroupIDURIString: String? = nil, presentedContentGroupKey: String? = nil) {
                self.url = url
                self.selectedIndex = selectedIndex
                self.articleKey = articleKey
                self.articleSectionAnchor = articleSectionAnchor
                self.talkPageSiteURLString = talkPageSiteURLString
                self.talkPageTitle = talkPageTitle
                self.talkPageTypeRawValue = talkPageTypeRawValue
                self.currentSavedViewRawValue = currentSavedViewRawValue
                self.readingListURIString = readingListURIString
                self.searchTerm = searchTerm
                self.shouldShowNavigationBar = shouldShowNavigationBar
                self.contentGroupIDURIString = contentGroupIDURIString
                self.presentedContentGroupKey = presentedContentGroupKey
            }
        }
    }
}

public struct NavigationState: Codable {
    static let libraryKey = "nav_state"

    public var viewControllers: [ViewController]
    public var shouldAttemptLogin: Bool

    public struct ViewController: Codable {
        public var kind: Kind
        public var presentation: Presentation
        public var info: Info?
        public var children: [ViewController]
        
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
            
            public var contentGroupIDURIString: String?

            public var presentedContentGroupKey: String?
            
            public var url: URL?
        }
    }
}

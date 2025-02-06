import Foundation

public final class WMFRecentlySearchedViewModel: ObservableObject {
    
    public struct Item: Identifiable {
        let text: String
        
        public init(text: String) {
            self.text = text
        }
        
        public var id: Int {
            return text.hash
        }
    }
    
    public init(recentSearchTerms: [Item]) {
        self.recentSearchTerms = recentSearchTerms
    }
    
    @Published var recentSearchTerms: [Item] = []
    @Published public var topPadding: CGFloat = 0
    
}

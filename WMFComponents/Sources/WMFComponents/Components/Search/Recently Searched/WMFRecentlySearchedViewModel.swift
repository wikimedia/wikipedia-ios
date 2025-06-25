import Foundation

public final class WMFRecentlySearchedViewModel: ObservableObject {

    public struct LocalizedStrings {
        public let title: String
        public let noSearches: String
        public let clearAll: String

        public init(title: String, noSearches: String, clearAll: String) {
            self.title = title
            self.noSearches = noSearches
            self.clearAll = clearAll
        }
    }

    public struct RecentSearchTerm: Identifiable {
        let text: String


        public init(text: String) {
            self.text = text
        }

        public var id: Int {
            return text.hash
        }
    }

    @Published var recentSearchTerms: [RecentSearchTerm] = []
    let localizedStrings: LocalizedStrings
    @Published public var topPadding: CGFloat = 0

    public init(recentSearchTerms: [RecentSearchTerm], localizedStrings: LocalizedStrings) {
        self.recentSearchTerms = recentSearchTerms
        self.localizedStrings = localizedStrings
    }

    func clearAll() { // should be async?
        self.recentSearchTerms.removeAll()
        // delete from other places
    }

}

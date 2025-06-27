import Foundation

public final class WMFRecentlySearchedViewModel: ObservableObject {

    public struct LocalizedStrings {
        public let title: String
        public let noSearches: String
        public let clearAll: String
        public let deleteActionAccessibilityLabel: String

        public init(title: String, noSearches: String, clearAll: String, deleteActionAccessibilityLabel: String) {
            self.title = title
            self.noSearches = noSearches
            self.clearAll = clearAll
            self.deleteActionAccessibilityLabel = deleteActionAccessibilityLabel
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

    @Published public var recentSearchTerms: [RecentSearchTerm] = []
    let localizedStrings: LocalizedStrings
    @Published public var topPadding: CGFloat = 0
    let deleteAllAction: () -> Void
    let deleteItemAction: (Int) -> Void

    public init(recentSearchTerms: [RecentSearchTerm], localizedStrings: LocalizedStrings, deleteAllAction: @escaping () -> Void, deleteItemAction: @escaping (Int) -> Void) {
        self.recentSearchTerms = recentSearchTerms
        self.localizedStrings = localizedStrings
        self.deleteAllAction = deleteAllAction
        self.deleteItemAction = deleteItemAction
    }

}

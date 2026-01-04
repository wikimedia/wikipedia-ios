import Foundation
import WMFData

public final class WMFRecentlySearchedViewModel: ObservableObject {

    public struct LocalizedStrings {
        public let title: String
        public let noSearches: String
        public let clearAll: String
        public let deleteActionAccessibilityLabel: String
        public let editButtonTitle: String

        public init(title: String, noSearches: String, clearAll: String, deleteActionAccessibilityLabel: String, editButtonTitle: String) {
            self.title = title
            self.noSearches = noSearches
            self.clearAll = clearAll
            self.deleteActionAccessibilityLabel = deleteActionAccessibilityLabel
            self.editButtonTitle = editButtonTitle
        }
    }

    @Published public var recentSearchTerms: [RecentSearchTerm] = []
    @Published public var topPadding: CGFloat = 0
    public let localizedStrings: LocalizedStrings
    let deleteAllAction: () -> Void
    let deleteItemAction: (Int) -> Void
    let selectAction: (RecentSearchTerm) -> Void

    public init(recentSearchTerms: [RecentSearchTerm], topPadding: CGFloat, localizedStrings: LocalizedStrings, deleteAllAction: @escaping () -> Void, deleteItemAction: @escaping (Int) -> Void, selectAction: @escaping (RecentSearchTerm) -> Void) {
        self.recentSearchTerms = recentSearchTerms
        self.topPadding = topPadding
        self.localizedStrings = localizedStrings
        self.deleteAllAction = deleteAllAction
        self.deleteItemAction = deleteItemAction
        self.selectAction = selectAction
    }

}

import Foundation
import WMFData

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
        public let text: String

        public init(text: String) {
            self.text = text
        }

        public var id: Int {
            return text.hash
        }
    }

    public var displayedSearchTerms: [RecentSearchTerm] {
        needsAttachedView ? Array(recentSearchTerms.prefix(3)) : recentSearchTerms
    }


    @Published public var recentSearchTerms: [RecentSearchTerm] = []
    let localizedStrings: LocalizedStrings
    @Published public var topPadding: CGFloat = 0
    let needsAttachedView: Bool
    let becauseYouReadViewModel: WMFBecauseYouReadViewModel?
    let deleteAllAction: () -> Void
    let deleteItemAction: (Int) -> Void
    let selectAction: (RecentSearchTerm) -> Void
    public let tabsDataController: WMFArticleTabsDataController
    public let devSettingsDataControler: WMFDeveloperSettingsDataController

    public init(recentSearchTerms: [RecentSearchTerm], localizedStrings: LocalizedStrings, needsAttachedView: Bool,  becauseYouReadViewModel: WMFBecauseYouReadViewModel?, deleteAllAction: @escaping () -> Void, deleteItemAction: @escaping (Int) -> Void, selectAction: @escaping (RecentSearchTerm) -> Void) {
        self.recentSearchTerms = recentSearchTerms
        self.localizedStrings = localizedStrings
        self.deleteAllAction = deleteAllAction
        self.deleteItemAction = deleteItemAction
        self.selectAction = selectAction
        self.needsAttachedView = needsAttachedView
        self.becauseYouReadViewModel = becauseYouReadViewModel
        self.tabsDataController =  WMFArticleTabsDataController.shared
        self.devSettingsDataControler = WMFDeveloperSettingsDataController.shared
    }

}

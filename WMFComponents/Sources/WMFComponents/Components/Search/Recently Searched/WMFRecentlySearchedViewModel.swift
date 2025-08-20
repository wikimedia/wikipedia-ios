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

    public struct RecentSearchTerm: Identifiable, Equatable {
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
    @Published public var topPadding: CGFloat = 0
    public let localizedStrings: LocalizedStrings
    let needsAttachedView: Bool
    let becauseYouReadViewModel: WMFBecauseYouReadViewModel?
    let didYouKnowViewModel: WMFNewArticleTabDidYouKnowViewModel?
    let deleteAllAction: () -> Void
    let deleteItemAction: (Int) -> Void
    let selectAction: (RecentSearchTerm) -> Void
    public let tabsDataController: WMFArticleTabsDataController
    public let devSettingsDataControler: WMFDeveloperSettingsDataController
    public let onTapEdit: () -> Void

    public init(recentSearchTerms: [RecentSearchTerm], localizedStrings: LocalizedStrings, needsAttachedView: Bool,  becauseYouReadViewModel: WMFBecauseYouReadViewModel?, didYouKnowViewModel: WMFNewArticleTabDidYouKnowViewModel?, deleteAllAction: @escaping () -> Void, deleteItemAction: @escaping (Int) -> Void, selectAction: @escaping (RecentSearchTerm) -> Void, onTapEdit: @escaping () -> Void) {
        self.recentSearchTerms = recentSearchTerms
        self.localizedStrings = localizedStrings
        self.deleteAllAction = deleteAllAction
        self.deleteItemAction = deleteItemAction
        self.selectAction = selectAction
        self.needsAttachedView = needsAttachedView
        self.becauseYouReadViewModel = becauseYouReadViewModel
        self.tabsDataController =  WMFArticleTabsDataController.shared
        self.devSettingsDataControler = WMFDeveloperSettingsDataController.shared
        self.onTapEdit = onTapEdit
        self.didYouKnowViewModel = didYouKnowViewModel
    }

}

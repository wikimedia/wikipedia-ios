import Foundation
import WMFComponents
import WMFData
import WMFTestKitchen

/// Sends the events of the Saved tab to the `apps-reading-list` instrument: the tab, its two
/// segments and the taps on a list or an article. The Discover list adds its own events through
/// `DiscoverInstrumentation`; the two share the instrument and the experiment fields.
@MainActor
final class SavedInstrumentation {

    static let shared = SavedInstrumentation()

    nonisolated static let instrumentName = "apps-reading-list"
    nonisolated private static let actionSource = "reading_list"

    private let instrument: InstrumentImpl
    private let dataController: WMFDiscoverDataController

    init(client: TestKitchenClient = TestKitchenAdapter.shared.client, dataController: WMFDiscoverDataController = .shared) {
        self.instrument = client.getInstrument(name: Self.instrumentName)
        self.dataController = dataController
    }

    // MARK: - Tab

    /// The reader tapped the Saved tab. The spec leaves the source empty until the app names
    /// every section.
    func logSavedTabTap() {
        submit(actionSource: nil, elementId: "saved_nav_icon")
    }

    /// The Saved tab showed one of its segments. The count is the number of lists in Reading
    /// lists and the number of articles in All articles.
    func logImpression(segment: WMFSavedViewModel.Segment, listCount: Int, articleCount: Int) {
        let actionContext: [String: Any]
        switch segment {
        case .readingLists:
            actionContext = ["list_count": listCount, "discover": dataController.isListTurnedOn]
        case .allArticles:
            actionContext = ["item_count": articleCount, "discover": dataController.isListTurnedOn]
        }
        submit(action: "impression", actionSubtype: segment.readingListActionSubtype, actionContext: actionContext)
    }

    // MARK: - Reading lists

    /// The reader opened one of their own lists. The Discover list has its own event.
    func logReadingListTap() {
        submit(actionSubtype: WMFSavedViewModel.Segment.readingLists.readingListActionSubtype, elementId: "reading_list_select")
    }

    /// The reader tapped Create list on the empty Reading lists segment.
    func logCreateListTap() {
        submit(elementId: "create_list_button")
    }

    // MARK: - All articles

    func logSavedArticleTap() {
        submit(actionSubtype: WMFSavedViewModel.Segment.allArticles.readingListActionSubtype, elementId: "saved_article_select")
    }

    // MARK: - Private

    private func submit(
        action: String = "click",
        actionSource: String? = SavedInstrumentation.actionSource,
        actionSubtype: String? = nil,
        elementId: String? = nil,
        actionContext: [String: Any] = [:]
    ) {
        instrument.submitInteraction(
            action: action,
            actionSource: actionSource,
            actionSubtype: actionSubtype,
            elementId: elementId,
            actionContext: actionContext.isEmpty ? nil : actionContext,
            experimentData: dataController.experimentData
        )
    }
}

extension WMFSavedViewModel.Segment {

    /// The segment in the names of the spec. Shared with the Discover events of the Saved tab.
    var readingListActionSubtype: String {
        switch self {
        case .allArticles: return "all_articles"
        case .readingLists: return "reading_list"
        }
    }
}

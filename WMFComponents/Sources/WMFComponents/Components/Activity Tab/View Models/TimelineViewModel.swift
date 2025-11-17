import WMFData
import Foundation

@MainActor
public final class TimelineViewModel {
    private let dataController: WMFActivityTabDataController
    var timeline: [Date: [TimelineItem]]?
    var pageSummaries: [String: WMFArticleSummary] = [:]

    public init(dataController: WMFActivityTabDataController) {
        self.dataController = dataController
    }

    public func fetch() async {
        do {
            let result = try await dataController.fetchTimeline()
            self.timeline = result
        } catch {
            debugPrint("error fetching timeline: \(error)")
        }
    }
}

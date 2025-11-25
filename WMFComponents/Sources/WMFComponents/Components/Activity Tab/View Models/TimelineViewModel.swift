import WMFData
import UIKit
import Combine

@MainActor
public final class TimelineViewModel: ObservableObject {

    private let dataController: WMFActivityTabDataController

    @Published var timeline: [Date: [TimelineItem]] = [:]
    @Published var pageSummaries: [String: WMFArticleSummary] = [:]

    public var onTapArticle: ((TimelineItem) -> Void)?

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

    public func fetchSummary(for item: TimelineItem) async -> WMFArticleSummary? {
        let itemID = item.id

        if let existing = pageSummaries[itemID] {
            return existing
        }

        do {
            if let summary = try await dataController.fetchSummary(for: item.page) {
                pageSummaries[itemID] = summary   // triggers UI update
                return summary
            }
        } catch {
            debugPrint("Failed to fetch summary for \(itemID): \(error)")
        }

        return nil
    }

    public func loadImage(imageURLString: String?) async throws -> UIImage? {
        let imageDataController = WMFImageDataController()
        guard let imageURLString,
              let url = URL(string: imageURLString) else {
            return nil
        }

        let data = try await imageDataController.fetchImageData(url: url)
        return UIImage(data: data)
    }

    public func deletePage(item: TimelineItem) {
        Task {
            do {
                try await dataController.deletePageView(for: item)

                let date = Calendar.current.startOfDay(for: item.date)

                if var items = timeline[date] {
                    items.removeAll { $0.id == item.id }
                    timeline[date] = items
                }
            } catch {
                print("Failed to delete page: \(error)")
            }
        }
    }

    func onTap(_ item: TimelineItem) {
        onTapArticle?(item)
    }
}

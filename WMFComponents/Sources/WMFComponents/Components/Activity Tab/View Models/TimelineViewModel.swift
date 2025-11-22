import WMFData
import UIKit
import Combine
import SwiftUI

@MainActor
public final class TimelineViewModel: ObservableObject {
    
    public final class TimelineSection: ObservableObject, Identifiable {
        internal init(date: Date, items: [TimelineItem]) {
            self.date = date
            self.items = items
        }
        
        let date: Date
        @Published public var items: [TimelineItem]
        
        public var id: Date { date }
        
    }

    private let dataController: WMFActivityTabDataController
    
    @Published var sections: [TimelineSection] = []

    public var onTapArticle: ((TimelineItem) -> Void)?

    public init(dataController: WMFActivityTabDataController) {
        self.dataController = dataController
    }

    public func fetch() async {
        do {
            let result = try await dataController.fetchTimeline()
            
            var sections = [TimelineSection]()
            for (key, value) in result {
                let sortedItems = value.sorted { $0.date > $1.date }
                sections.append(TimelineSection(date: key, items: sortedItems))
            }
            
            let sortedSections = sections.sorted { $0.date > $1.date }
            self.sections = sortedSections
        } catch {
            debugPrint("error fetching timeline: \(error)")
        }
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

    public func deletePage(item: TimelineItem, section: TimelineSection) {
        Task {
            do {
                try await dataController.deletePageView(for: item)
                
            } catch {
                print("Failed to delete page: \(error)")
            }
        }

        section.items.removeAll { $0.id == item.id }
        
        if section.items.isEmpty {
            sections.removeAll { $0.id == section.id }
        }
    }

    func onTap(_ item: TimelineItem) {
        onTapArticle?(item)
    }
}

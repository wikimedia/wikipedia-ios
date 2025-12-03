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
    weak var activityTabViewModel: WMFActivityTabViewModel?
    
    @Published var sections: [TimelineSection] = []

    public var onTapArticle: ((TimelineItem) -> Void)?

    public init(dataController: WMFActivityTabDataController) {
        self.dataController = dataController
    }
    
    var shouldShowEmptyState: Bool {
        return self.sections.count == 1 && (self.sections.first?.items.isEmpty ?? true)
    }

    public func fetch() async {
        do {
            let result = try await dataController.getTimelineItems()
            
            var sections = [TimelineSection]()
            
            // Business rule: if there are no items, we still want a section that says "Today"
            // https://phabricator.wikimedia.org/T409200
            if result.isEmpty {
                sections.append(TimelineSection(date: Date(), items: []))
            } else {
                for (key, value) in result {
                    
                    var filteredValues = value
                    
                    // If user is logged out, only show viewed items
                    if let activityTabViewModel, activityTabViewModel.authenticationState != .loggedIn {
                        filteredValues = value.filter { $0.itemType != .edit && $0.itemType != .saved }
                    }
                    
                    let sortedFilteredValues = filteredValues.sorted { $0.date > $1.date }
                    
                    sections.append(TimelineSection(date: key, items: sortedFilteredValues))
                }
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

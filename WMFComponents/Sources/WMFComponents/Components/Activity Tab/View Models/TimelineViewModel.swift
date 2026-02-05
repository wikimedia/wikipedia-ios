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

    public var onTapArticle: ((TimelineItem) -> Void)?
    public var onTapEditArticle: ((TimelineItem) -> Void)?

    private var username: String?

    public init(dataController: WMFActivityTabDataController, username: String? = nil) {
        self.dataController = dataController
        self.username = username
    }

    public func setUser(username: String?) {
        self.username = username
    }

    public func fetch() async {
        do {
            let result = try await dataController.getTimelineItems(username: username)
            var sections = [TimelineSection]()

            // Business rule: if there are no items, we still want a section that says "Today"
            // https://phabricator.wikimedia.org/T409200
            if result.isEmpty {
                sections.append(TimelineSection(date: Date(), items: []))
            } else {
                for (key, value) in result {
                    var filteredValues = value

                    if let activityTabViewModel, activityTabViewModel.authenticationState != .loggedIn {
                        filteredValues = value.filter { $0.itemType != .edit && $0.itemType != .saved }
                    }

                    let sortedFilteredValues = filteredValues.sorted { $0.date > $1.date }
                    if !sortedFilteredValues.isEmpty {
                        sections.append(TimelineSection(date: key, items: sortedFilteredValues))
                    }
                }
                
                if sections.isEmpty {
                    sections.append(TimelineSection(date: Date(), items: []))
                }
            }

            let sortedSections = sections.sorted { $0.date > $1.date }
            self.activityTabViewModel?.sections = sortedSections
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

        // Delete item
        section.items.removeAll { $0.id == item.id }
        
        // If last item, delete section
        var currentSections = activityTabViewModel?.sections ?? []
        
        if section.items.isEmpty {
            currentSections.removeAll { $0.id == section.id }
        }
        
        // If last section, bring back one section with empty items
        
        // Business rule: if there are no items, we still want a section that says "Today"
        // https://phabricator.wikimedia.org/T409200
        if currentSections.isEmpty {
            currentSections.append(TimelineSection(date: Date(), items: []))
        }
        
        self.activityTabViewModel?.sections = currentSections
    }

    func onTap(_ item: TimelineItem) {
        onTapArticle?(item)
    }
    
    func onTapEdit(_ item: TimelineItem) {
        onTapEditArticle?(item)
    }
}

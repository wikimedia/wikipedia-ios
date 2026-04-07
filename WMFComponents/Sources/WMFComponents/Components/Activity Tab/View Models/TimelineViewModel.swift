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
            
            let existingSections = activityTabViewModel?.sections ?? []
            var updatedSections = [TimelineSection]()
            
            if result.isEmpty {
                // Check if we already have an empty "today" section
                if existingSections.count == 1,
                   let existingToday = existingSections.first(where: { Calendar.current.isDateInToday($0.date) && $0.items.isEmpty }) {
                    updatedSections.append(existingToday)
                } else {
                    updatedSections.append(TimelineSection(date: Date(), items: []))
                }
            } else {
                for (key, value) in result {
                    var filteredValues = value
                    
                    if let activityTabViewModel, activityTabViewModel.authenticationState != .loggedIn {
                        filteredValues = value.filter { $0.itemType != .edit && $0.itemType != .saved }
                    }
                    
                    let sortedFilteredValues = filteredValues.sorted { $0.date > $1.date }
                    
                    guard !sortedFilteredValues.isEmpty else { continue }
                    
                    // Check if we already have a section for this date
                    if let existingSection = existingSections.first(where: { $0.date == key }) {
                        // Update items only if they've changed
                        let existingItemIds = Set(existingSection.items.map { $0.id })
                        let newItemIds = Set(sortedFilteredValues.map { $0.id })
                        
                        if existingItemIds != newItemIds {
                            // Reuse existing items where possible, only add truly new ones
                            var mergedItems = [TimelineItem]()
                            for newItem in sortedFilteredValues {
                                if let existingItem = existingSection.items.first(where: { $0.id == newItem.id }) {
                                    mergedItems.append(existingItem)
                                } else {
                                    mergedItems.append(newItem)
                                }
                            }
                            existingSection.items = mergedItems
                        }
                        updatedSections.append(existingSection)
                    } else {
                        // Truly new section
                        updatedSections.append(TimelineSection(date: key, items: sortedFilteredValues))
                    }
                }
                
                if updatedSections.isEmpty {
                    if existingSections.count == 1,
                       let existingToday = existingSections.first(where: { Calendar.current.isDateInToday($0.date) && $0.items.isEmpty }) {
                        updatedSections.append(existingToday)
                    } else {
                        updatedSections.append(TimelineSection(date: Date(), items: []))
                    }
                }
            }
            
            let sortedSections = updatedSections.sorted { $0.date > $1.date }
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

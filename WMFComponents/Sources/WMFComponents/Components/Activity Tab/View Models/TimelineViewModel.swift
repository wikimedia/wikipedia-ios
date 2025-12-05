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

    public init(dataController: WMFActivityTabDataController) {
        self.dataController = dataController
    }

    public func fetch() async {
        do {
            let result = try await dataController.getTimelineItems()

            // 1. Build new section map from fetched items
            var newSectionsByDate: [Date: TimelineSection] = [:]

            if result.isEmpty {
                newSectionsByDate[Date()] = TimelineSection(date: Date(), items: [])
            } else {
                for (date, items) in result {

                    var filtered = items

                    if let parent = activityTabViewModel,
                       parent.authenticationState != .loggedIn {
                        filtered = filtered.filter { $0.itemType != .edit && $0.itemType != .saved }
                    }

                    let sorted = filtered.sorted { $0.date > $1.date }

                    if !sorted.isEmpty {
                        newSectionsByDate[date] = TimelineSection(date: date, items: sorted)
                    }
                }
            }

            // 2. Old sections
            guard let parent = activityTabViewModel else { return }
            var oldSections = parent.sections

            // 3. Patch existing sections by matching date
            var updatedSections: [TimelineSection] = []

            for (date, newSection) in newSectionsByDate {
                if let existing = oldSections.first(where: { $0.date == date }) {
                    // Mutate existing section to preserve identity
                    withAnimation(.default) {
                        existing.items = patchItems(old: existing.items, new: newSection.items)
                    }
                    updatedSections.append(existing)
                } else {
                    // No old section → insert the new one
                    // withAnimation(.default) {
                        updatedSections.append(newSection)
                    // }
                }
            }

            // 4. Remove old sections that disappeared
            // (Skip this if you prefer to preserve history even when empty.)
            // updatedSections already ignores removed dates.

            // 5. Sort
            
            // withAnimation(.default) {
                updatedSections.sort { $0.date > $1.date }
                parent.sections = updatedSections
            // }

        } catch {
            debugPrint("error fetching timeline: \(error)")
        }
    }
    
    func patchItems(old: [TimelineItem], new: [TimelineItem]) -> [TimelineItem] {
        // Build a map of old by id but only for lookup (keep first occurrence)
        var existingByID: [String: TimelineItem] = [:]
        for item in old {
            if existingByID[item.id] == nil {
                existingByID[item.id] = item
            }
        }

        // Dedupe new by id while preserving order, preferring the last
        var seenNewIDs = Set<String>()
        var uniqueNew: [TimelineItem] = []
        for item in new {
            if !seenNewIDs.contains(item.id) {
                uniqueNew.append(item)
                seenNewIDs.insert(item.id)
            }
        }

        // Build result: prefer the `new` value (so updates to content show)
        var result: [TimelineItem] = []
        for item in uniqueNew {
            // If you wanted to preserve the old instance instead, swap the branches below:
            result.append(item)                 // prefer new (applies content updates)
            // if let existing = existingByID[item.id] { result.append(existing) } else { result.append(item) }
        }

        return result
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
}

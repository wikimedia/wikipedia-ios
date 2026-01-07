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

    /// Optional user info for fetching edits
    private var username: String?
    private var project: WMFProject?

    public init(dataController: WMFActivityTabDataController, username: String? = nil, project: WMFProject? = nil) {
        self.dataController = dataController
        self.username = username
        self.project = project
    }

    public func setUser(username: String) {
        self.username = username
    }
    
    public func setProject(project: WMFProject) {
        self.project = project
    }

    public func fetch() async {
        do {
            let result = try await dataController.getTimelineItems()
            var sections = [TimelineSection]()

            // Fetch edits if user is logged in
            var editItems: [TimelineItem] = []
            editItems = await fetchEditedArticles()
            
            // Combine timeline result with edits
            var combinedResult = result
            for editItem in editItems {
                let day = Calendar.current.startOfDay(for: editItem.date)
                combinedResult[day, default: []].append(editItem)
            }

            // Business rule: if there are no items, we still want a section that says "Today"
            // https://phabricator.wikimedia.org/T409200
            if combinedResult.isEmpty {
                sections.append(TimelineSection(date: Date(), items: []))
            } else {
                for (key, value) in combinedResult {
                    var filteredValues = value

                    // If user is logged out, only show viewed items
                    if let activityTabViewModel, activityTabViewModel.authenticationState != .loggedIn {
                        filteredValues = value.filter { $0.itemType != .edit && $0.itemType != .saved }
                    }

                    let sortedFilteredValues = filteredValues.sorted { $0.date > $1.date }
                    if !sortedFilteredValues.isEmpty {
                        sections.append(TimelineSection(date: key, items: sortedFilteredValues))
                    }
                }
            }

            let sortedSections = sections.sorted { $0.date > $1.date }
            self.activityTabViewModel?.sections = sortedSections
        } catch {
            debugPrint("error fetching timeline: \(error)")
        }
    }

    func fetchEditedArticles() async -> [TimelineItem] {
        guard let username, let project else { return [] }

        do {
            let edits = try await UserContributionsDataController.shared.fetchRecentArticleEdits(
                username: username,
                project: project
            )

            return edits.map { edit in
                TimelineItem(
                    id: "edit~\(edit.projectID)~\(edit.title)~\(edit.timestamp.timeIntervalSince1970)",
                    date: edit.timestamp,
                    titleHtml: edit.title,
                    projectID: edit.projectID,
                    pageTitle: edit.title,
                    url: edit.articleURL,
                    namespaceID: 0,
                    itemType: .edit
                )
            }
        } catch {
            debugPrint("Failed to fetch user edits: \(error)")
            return []
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
}

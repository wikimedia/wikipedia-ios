import SwiftUI
import WMFData

@MainActor
final class WMFAsyncPageRowSavedViewModel: ObservableObject, Identifiable, @MainActor Equatable {
    
    struct LocalizedStrings {
        let open: String
        let openInNewTab: String
        let openInBackgroundTab: String
        let removeFromSaved: String
        let share: String
        let listLimitExceeded: String
        let entryLimitExceeded: String
        let notSynced: String
        let articleQueuedToBeDownloaded: String
    }
    
    let id: String
    let title: String
    let project: WMFProject
    let localizedStrings: LocalizedStrings
    
    @Published var readingListNames: [String]
    @Published private(set) var description: String?
    @Published private(set) var imageURL: URL?
    @Published private(set) var uiImage: UIImage?
    @Published var alertType: WMFSavedArticleAlertType = .none
    
    var geometryFrame: CGRect = .zero
    var snippet: String?
    
    private let dataController: WMFArticleSummaryDataController
    
    public static func == (lhs: WMFAsyncPageRowSavedViewModel, rhs: WMFAsyncPageRowSavedViewModel) -> Bool {
        lhs.id == rhs.id &&
        lhs.title == rhs.title &&
        lhs.project == rhs.project &&
        lhs.readingListNames == rhs.readingListNames
    }
    
    public var isAlertHidden: Bool {
        return alertType == .none
    }
    
    init(id: String, title: String, project: WMFProject, readingListNames: [String], alertType: WMFSavedArticleAlertType = .none, localizedStrings: LocalizedStrings) {
        self.id = id
        self.title = title
        self.project = project
        self.readingListNames = readingListNames
        self.dataController = WMFArticleSummaryDataController.shared
        self.alertType = alertType
        self.localizedStrings = localizedStrings
        Task {
            await self.fetchArticleDetails()
        }
    }
    
    // MARK: - Update Methods
    public func updateAlertType(_ newAlertType: WMFSavedArticleAlertType) {
        if alertType != newAlertType {
            alertType = newAlertType
        }
    }
    
    @MainActor
    private func fetchArticleDetails() async {
        do {
            let summary = try await dataController.fetchArticleSummary(project: project, title: title)
            self.description = summary.description
            self.snippet = summary.extract
            
            let imageDataController = WMFImageDataController()
            
            guard let thumbnailURL = summary.thumbnailURL else {
                return
            }
            self.imageURL = thumbnailURL
            
            let data = try await imageDataController.fetchImageData(url: thumbnailURL)
            
            self.uiImage = UIImage(data: data)
        } catch {
            // Silently fail - cell will display without description/image
        }
    }
}

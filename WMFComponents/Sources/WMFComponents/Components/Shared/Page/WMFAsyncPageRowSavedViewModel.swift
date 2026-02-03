import SwiftUI
import WMFData

@MainActor
final class WMFAsyncPageRowSavedViewModel: ObservableObject, Identifiable, Equatable {
    
    enum ImageLoadingState {
        case loading
        case loaded
        case noImage
    }
    
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
    @Published var isEditing: Bool = false
    @Published var isSelected: Bool = false
    @Published private(set) var imageLoadingState: ImageLoadingState = .loading
    
    var geometryFrame: CGRect = .zero
    var snippet: String?
    
    public var didTapAlert: (() -> Void)?
    public var didTapReadingListTag: ((_ readingListName: String?) -> Void)?
    
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
            
            if let description = summary.description,
               !description.isEmpty {
                self.description = description
            } else {
                self.description = summary.extract?.replacingOccurrences(of: "\n", with: "")
            }
            
            self.snippet = summary.extract
            
            guard let thumbnailURL = summary.thumbnailURL else {
                self.imageLoadingState = .noImage
                return
            }
            self.imageURL = thumbnailURL
            
            let imageDataController = WMFImageDataController()
            let data = try await imageDataController.fetchImageData(url: thumbnailURL)
            
            self.uiImage = UIImage(data: data)
            self.imageLoadingState = .loaded
        } catch {
            self.imageLoadingState = .noImage
        }
    }
}

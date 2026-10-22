import SwiftUI
import WMFData

@MainActor
final class WMFPageRowSavedViewModel: ObservableObject, Identifiable, Equatable {
    
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
    let snippet: String?
    
    public var didTapAlert: (() -> Void)?
    public var didTapReadingListTag: ((_ readingListName: String?) -> Void)?
    
    public static func == (lhs: WMFPageRowSavedViewModel, rhs: WMFPageRowSavedViewModel) -> Bool {
        lhs.id == rhs.id &&
        lhs.title == rhs.title &&
        lhs.project == rhs.project &&
        lhs.readingListNames == rhs.readingListNames
    }
    
    public var isAlertHidden: Bool {
        return alertType == .none
    }
    
    /// The description, snippet and thumbnail come from the saved article record on device. The row
    /// only loads the thumbnail bytes; it does not ask the network for a summary.
    init(
        id: String,
        title: String,
        project: WMFProject,
        description: String?,
        snippet: String? = nil,
        thumbnailURL: URL?,
        readingListNames: [String],
        alertType: WMFSavedArticleAlertType = .none,
        localizedStrings: LocalizedStrings
    ) {
        self.id = id
        self.title = title
        self.project = project
        self.description = description
        self.snippet = snippet
        self.imageURL = thumbnailURL
        self.readingListNames = readingListNames
        self.alertType = alertType
        self.localizedStrings = localizedStrings
        self.imageLoadingState = thumbnailURL == nil ? .noImage : .loading
        if thumbnailURL != nil {
            Task {
                await self.loadThumbnail()
            }
        }
    }

    // MARK: - Update Methods
    public func updateAlertType(_ newAlertType: WMFSavedArticleAlertType) {
        if alertType != newAlertType {
            alertType = newAlertType
        }
    }
    
    @MainActor
    private func loadThumbnail() async {
        guard let imageURL else {
            imageLoadingState = .noImage
            return
        }

        do {
            let data = try await WMFImageDataController.shared.fetchImageData(url: imageURL)
            self.uiImage = UIImage(data: data)
            self.imageLoadingState = .loaded
        } catch {
            self.imageLoadingState = .noImage
        }
    }
}

import SwiftUI
import WMFData

@MainActor
final class WMFPageRowSavedViewModel: ObservableObject, Identifiable, Equatable {
    
    enum ImageLoadingState {
        case loading
        case loaded
        case noImage
    }
    
    let id: String
    let title: String
    let project: WMFProject
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
        alertType: WMFSavedArticleAlertType = .none
    ) {
        self.id = id
        self.title = title
        self.project = project
        self.description = description
        self.snippet = snippet
        self.imageURL = thumbnailURL
        self.readingListNames = readingListNames
        self.alertType = alertType
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

        if let image = await UIImage.loadFaceCropped(from: imageURL) {
            self.uiImage = image
            self.imageLoadingState = .loaded
        } else {
            self.imageLoadingState = .noImage
        }
    }
}

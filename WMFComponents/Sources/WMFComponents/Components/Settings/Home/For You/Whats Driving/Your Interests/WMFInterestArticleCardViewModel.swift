import Foundation
import WMFData
import UIKit

@MainActor
final class WMFInterestArticleCardViewModel: ObservableObject, Identifiable {

    let id: Int
    let title: String
    let description: String?
    private let thumbnailURL: URL?

    @Published var uiImage: UIImage?
    private var imageTask: Task<Void, Never>?

    init(article: WMFRandomArticle) {
        self.id = article.pageid
        self.title = article.displayTitle ?? article.title
        self.description = article.description
        self.thumbnailURL = article.thumbnail?.url
    }

    func loadImageIfNeeded() {
        guard uiImage == nil, let url = thumbnailURL else { return }
        imageTask?.cancel()
        imageTask = Task {
            guard let data = try? await WMFImageDataController.shared.fetchImageData(url: url),
                  !Task.isCancelled else { return }
            self.uiImage = UIImage(data: data)
        }
    }

    deinit {
        imageTask?.cancel()
    }
}

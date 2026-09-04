import Combine
import Foundation
import UIKit
import WMFData
import WMFNativeLocalizations

// MARK: - Community Feed View Model

@MainActor
public final class WMFCommunityFeedViewModel: ObservableObject, Identifiable {
    public init() {
        // noop
    }
    
    public let disclaimerString = WMFLocalizedString("community-feed-disclaimer", value: "Content and resources selected by and about the Wikimedia community", comment: "Disclaimer string in community feced")
}

// MARK: - Featured Article Image View Model

@MainActor
final class WMFFeaturedArticleImageViewModel: ObservableObject {
    @Published var uiImage: UIImage?

    func load(url: URL) {
        Task {
            guard let data = try? await WMFImageDataController.shared.fetchImageData(url: url) else { return }
            self.uiImage = UIImage(data: data)
        }
    }
}

// MARK: - News Story Image View Model

@MainActor
final class WMFNewsStoryImageViewModel: ObservableObject {
    @Published var uiImage: UIImage?
    private var loadTask: Task<Void, Never>?

    func load(url: URL) {
        loadTask?.cancel()
        loadTask = Task {
            guard let data = try? await WMFImageDataController.shared.fetchImageData(url: url) else { return }
            self.uiImage = UIImage(data: data)
        }
    }

    deinit {
        loadTask?.cancel()
    }
}

// MARK: - Picture of the Day Image View Model

@MainActor
final class WMFPictureOfTheDayImageViewModel: ObservableObject {
    @Published var uiImage: UIImage?

    func load(url: URL) {
        Task {
            guard let data = try? await WMFImageDataController.shared.fetchImageData(url: url) else { return }
            self.uiImage = UIImage(data: data)
        }
    }
}

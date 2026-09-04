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

    // MARK: - Localized Strings

    public let disclaimerString = WMFLocalizedString("community-feed-disclaimer", value: "Content and resources selected by and about the Wikimedia community", comment: "Disclaimer shown at the top of the Community feed, explaining that everything below it was chosen by and is about the Wikimedia community of volunteer editors.")

    public let seePastContentTitle = WMFLocalizedString("home-community-see-past-content", value: "See past community content", comment: "Button at the bottom of the Community feed that loads content from previous days.")

    public let featuredArticleTitle = WMFLocalizedString("home-community-featured-article-title", value: "Featured Article", comment: "Section header in the Community feed. Labels the article that volunteer editors featured on the main page of the selected language Wikipedia today.")
    public let featuredArticleSubtitle = WMFLocalizedString("home-community-featured-article-subtitle", value: "Featured articles are some of the best articles on Wikipedia, selected daily by editors", comment: "Subtitle for the Featured Article section in the Community feed. Explains that the article was selected by volunteer editors and is featured on the main page of the selected language Wikipedia today.")

    public let topReadTitle = WMFLocalizedString("home-community-top-read-title", value: "Top read", comment: "Section header in the Community feed. Labels a list of the most read articles on the selected language Wikipedia.")

    public let inTheNewsTitle = WMFLocalizedString("home-community-in-the-news-title", value: "In the news", comment: "Section header in the Community feed. Labels current news stories that link to related Wikipedia articles.")

    public let onThisDayTitle = WMFLocalizedString("home-community-on-this-day-title", value: "On this day", comment: "Section header in the Community feed. Labels a list of historical events that happened on today's calendar date.")

    public let pictureOfTheDayTitle = WMFLocalizedString("home-community-picture-of-the-day-title", value: "Picture of the day", comment: "Section header in the Community feed. Labels the image selected as picture of the day on Wikimedia Commons.")
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

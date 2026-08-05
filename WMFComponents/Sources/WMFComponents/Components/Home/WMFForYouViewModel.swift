import Foundation
import UIKit
import SwiftUI
import WMFData
import WMFNativeLocalizations

// MARK: - Module types and visibility

public enum WMFForYouModule {
    case basedOnInterests
    case becauseYouRead
    case continueReading
}

public struct WMFForYouModuleVisibility {
    public var basedOnInterests: Bool
    public var becauseYouRead: Bool
    public var continueReading: Bool

    public init(basedOnInterests: Bool, becauseYouRead: Bool, continueReading: Bool) {
        self.basedOnInterests = basedOnInterests
        self.becauseYouRead = becauseYouRead
        self.continueReading = continueReading
    }

    public func isVisible(_ module: WMFForYouModule) -> Bool {
        switch module {
        case .basedOnInterests: return basedOnInterests
        case .becauseYouRead: return becauseYouRead
        case .continueReading: return continueReading
        }
    }
}

// MARK: - Header label

public struct WMFForYouHeaderLabel {
    public let symbolName: String?
    public let prefix: String
    public let boldSuffix: String

    public init(symbolName: String? = nil, prefix: String, boldSuffix: String) {
        self.symbolName = symbolName
        self.prefix = prefix
        self.boldSuffix = boldSuffix
    }
}

// MARK: - View models

@MainActor
public final class WMFForYouViewModel: ObservableObject {

    @Published public var pages: [WMFForYouPageViewModel] = []
    @Published public var moduleVisibility: WMFForYouModuleVisibility
    @Published public var hiddenCardKeys: Set<String>

    public var onRefresh: (() async -> Void)?
    public var onHideModule: ((WMFForYouModule) -> Void)?
    public var onHideCard: ((WMFForYouArticleCardViewModel) -> Void)?
    public var onCustomizeInterests: (() -> Void)?
    public var onTapCard: ((WMFForYouArticleCardViewModel) -> Void)?
    public var onSaveCard: ((WMFForYouArticleCardViewModel) -> Void)?
    public var onShareCard: ((WMFForYouArticleCardViewModel) -> Void)?
    public var onUnsaveCard: ((WMFForYouArticleCardViewModel) -> Void)?

    public let emptyTitle = WMFLocalizedString("for-you-empty-title", value: "Nothing here yet", comment: "Title shown on the For You tab when there is no content to display.")
    public let emptySubtitle = WMFLocalizedString("for-you-empty-subtitle", value: "Add interests to get personalized article recommendations.", comment: "Subtitle shown on the For You tab empty state encouraging the user to add interests.")
    public let emptyButtonTitle = WMFLocalizedString("for-you-empty-button", value: "Choose your interests", comment: "Button on the For You empty state that opens the interests customization screen.")

    public init(
        response: WMFForYouResponse,
        moduleVisibility: WMFForYouModuleVisibility = WMFForYouModuleVisibility(basedOnInterests: true, becauseYouRead: true, continueReading: true),
        hiddenCardKeys: Set<String> = []
    ) {
        self.moduleVisibility = moduleVisibility
        self.hiddenCardKeys = hiddenCardKeys

        var seenTitles: Set<String> = []

        func makeKey(_ article: WMFForYouArticle) -> String {
            "\(article.project.id)_\(article.title)"
        }

        func deduplicated(_ articles: [WMFForYouArticle]) -> [WMFForYouArticle] {
            articles.filter { seenTitles.insert(makeKey($0)).inserted }
        }

        let topicPages = response.interestTopicRandomArticles.map {
            let header = WMFForYouHeaderLabel(
                prefix: WMFLocalizedString("for-you-header-interest-topic-prefix", value: "Because of your interest: ", comment: "Prefix for a For You feed card header based on an interest topic."),
                boldSuffix: $0.topic.displayName
            )
            return WMFForYouPageViewModel(module: .basedOnInterests, headerLabel: header, articles: deduplicated($0.articles))
        }
        let relatedPages = response.interestPageRelatedArticles.map {
            let header = WMFForYouHeaderLabel(
                prefix: WMFLocalizedString("for-you-header-interest-article-prefix", value: "Because of your interest: ", comment: "Prefix for a For You feed card header based on an article the user has shown interest in."),
                boldSuffix: $0.pageInterest.title
            )
            return WMFForYouPageViewModel(module: .basedOnInterests, headerLabel: header, articles: deduplicated($0.articles))
        }
        let becauseYouReadPage: [WMFForYouPageViewModel] = response.becauseYouReadArticles.map {
            let header = WMFForYouHeaderLabel(
                symbolName: "clock",
                prefix: WMFLocalizedString("for-you-header-because-you-read-prefix", value: "Because you read: ", comment: "Prefix for a For You feed card header shown because the user recently read a related article."),
                boldSuffix: $0.recentlyRead.title.normalize
            )
            return [WMFForYouPageViewModel(module: .becauseYouRead, headerLabel: header, articles: deduplicated($0.articles))]
        } ?? []
        let continueReadingPage: [WMFForYouPageViewModel] = response.continueReadingArticles.map { continueReading in
            let continueHeader = WMFForYouHeaderLabel(
                symbolName: "doc.text",
                prefix: WMFLocalizedString("for-you-header-continue-reading-prefix", value: "Continue reading: ", comment: "Prefix for a For You feed card header prompting the user to continue reading an article."),
                boldSuffix: continueReading.continueReadingArticle.title.normalize
            )
            let continueCard = WMFForYouArticleCardViewModel(
                article: continueReading.continueReadingArticle,
                headerLabel: continueHeader
            )
            seenTitles.insert(makeKey(continueReading.continueReadingArticle))
            let savedCards = deduplicated(continueReading.savedArticles).map {
                let savedHeader = WMFForYouHeaderLabel(
                    symbolName: "bookmark.fill",
                    prefix: WMFLocalizedString("for-you-header-saved-article-prefix", value: "From your reading list: ", comment: "Prefix for a For You feed card header showing a saved article."),
                    boldSuffix: $0.title
                )
                return WMFForYouArticleCardViewModel(article: $0, headerLabel: savedHeader)
            }
            return [WMFForYouPageViewModel(module: .continueReading, articleViewModels: [continueCard] + savedCards)]
        } ?? []

        let allInterestPages = topicPages + relatedPages
        let firstInterests = Array(allInterestPages.prefix(3))
        let remainingInterests = Array(allInterestPages.dropFirst(3))

        self.pages = firstInterests + becauseYouReadPage + continueReadingPage + remainingInterests
    }
}

@MainActor
public final class WMFForYouPageViewModel: ObservableObject, Identifiable {

    public let id = UUID()
    public let module: WMFForYouModule
    public let articleViewModels: [WMFForYouArticleCardViewModel]

    public init(module: WMFForYouModule, headerLabel: WMFForYouHeaderLabel, articles: [WMFForYouArticle]) {
        self.module = module
        self.articleViewModels = articles.map {
            WMFForYouArticleCardViewModel(article: $0, headerLabel: headerLabel)
        }
        Self.assignCardIndexes(to: articleViewModels)
    }

    public init(module: WMFForYouModule, articleViewModels: [WMFForYouArticleCardViewModel]) {
        self.module = module
        self.articleViewModels = articleViewModels
        Self.assignCardIndexes(to: articleViewModels)
    }

    /// Fixes each card's position in the carousel at build time. Both initialisers go through here
    /// so a card's design never depends on which other cards happen to be hidden.
    private static func assignCardIndexes(to cards: [WMFForYouArticleCardViewModel]) {
        for (index, card) in cards.enumerated() {
            card.cardIndex = index
        }
    }
}

@MainActor
public final class WMFForYouArticleCardViewModel: ObservableObject, Identifiable {

    public let id = UUID()
    public let headerLabel: WMFForYouHeaderLabel
    public let title: String
    public let project: WMFProject
    @Published public var description: String?
    @Published public var extract: String?
    @Published public var uiImage: UIImage?
    @Published public var sampledColor: Color?
    @Published public var isSaved: Bool = false

    /// Position of this card in its carousel, fixed once by `WMFForYouPageViewModel` when the page
    /// is built. The card design is chosen from this, so it must not follow the live filtered
    /// position - otherwise hiding one card re-styles every card after it.
    public fileprivate(set) var cardIndex: Int = 0

    public enum LoadState {
        case loading, loaded
    }
    @Published public var loadState: LoadState = .loading

    /// Whether this article has an image to show.
    public enum ImageAvailability {
        case unknown /// The summary has not arrived yet, so we do not know.
        case available
        case unavailable
    }
    @Published public var imageAvailability: ImageAvailability = .unknown

    public func refreshSavedState(isSaved: Bool) {
        self.isSaved = isSaved
    }

    public func toggleSaved() {
        isSaved.toggle()
    }

    private var loadTask: Task<Void, Never>?

    public let hideKey: String

    // MARK: - Localized strings

    public var saveTitle: String {
        CommonStrings.shortSaveTitle
    }

    public var unsaveTitle: String {
        CommonStrings.shortUnsaveTitle
    }

    public var shareTitle: String {
        CommonStrings.shortShareTitle
    }

    public var hideCardTitle: String {
        CommonStrings.hideCardTitle
    }

    public let hideModuleTitle = WMFLocalizedString("for-you-menu-hide-module", value: "Hide module", comment: "Menu action to hide the entire For You feed module that contains this card.")

    public let customizeInterestsTitle = WMFLocalizedString("for-you-menu-customize-interests", value: "Customize interests", comment: "Menu action to open the interests customization screen from a For You feed card.")

    public let miniCardLabel = WMFLocalizedString("for-you-mini-card-label", value: "Mini card", comment: "Small label displayed above the title on the mini card variant of the For You feed card.")

    public init(article: WMFForYouArticle, headerLabel: WMFForYouHeaderLabel) {
        self.headerLabel = headerLabel
        self.title = article.title
        self.project = article.project
        self.description = article.title
        self.hideKey = "for_you_\(article.project.id)_\(article.title)"
    }

    public func load() {
        guard loadTask == nil else { return }
        loadTask = Task { [weak self] in
            guard let self else { return }
            guard let summary = try? await WMFArticleSummaryDataController.shared.fetchArticleSummary(project: project, title: title) else {
                self.imageAvailability = .unavailable
                self.loadState = .loaded
                return
            }
            self.description = summary.description
            self.extract = summary.extract
            guard let thumbnailURL = summary.thumbnailURL else {
                self.imageAvailability = .unavailable
                self.loadState = .loaded
                return
            }

            // The article has an image, so let the card settle on its image design now. The image
            // itself arrives later, and only a failed download changes the design after this.
            self.imageAvailability = .available

            // Upsize the Wikimedia thumbnail URL to get a higher resolution image
            let largeURL: URL = {
                var urlString = thumbnailURL.absoluteString
                if let range = urlString.range(of: #"/\d+px-"#, options: .regularExpression) {
                    urlString.replaceSubrange(range, with: "/1280px-")
                }
                return URL(string: urlString) ?? thumbnailURL
            }()

            guard let data = try? await WMFImageDataController.shared.fetchImageData(url: largeURL) else {
                self.imageAvailability = .unavailable
                self.loadState = .loaded
                return
            }

            self.uiImage = UIImage(data: data)

            // Sample off the main actor. The pixel loop is far too expensive to run while the
            // user is swiping between cards, and the image is on screen before it finishes.
            if let color = await WMFForYouImageColorSampler.shared.sampledColor(from: data) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.sampledColor = color
                }
            }
            self.loadState = .loaded
        }
    }

    deinit {
        loadTask?.cancel()
    }
}

// MARK: - WCAG color sampling

/// Runs the card background colour sampling away from the main actor.
///
/// This is an actor rather than a `nonisolated` function for two reasons. First, an actor is
/// guaranteed never to run on the main actor, so the work cannot drift back onto the main thread
/// if the package's concurrency defaults change later. Second, it serialises the sampling: several
/// cards can scroll in at once, and we do not want each of them looping over a large image at the
/// same time.
actor WMFForYouImageColorSampler {

    static let shared = WMFForYouImageColorSampler()

    /// Takes image `Data` instead of a `UIImage` because `UIImage` is not `Sendable` and so cannot
    /// be handed to another concurrency domain. The image is decoded here instead.
    func sampledColor(from imageData: Data) -> Color? {
        return UIImage(data: imageData)?.accessibleSampledColor()
    }
}

extension UIImage {
    func accessibleSampledColor() -> Color? {
        guard let cgImage else { return nil }
        let width = cgImage.width
        let height = cgImage.height
        guard width > 0, height > 0 else { return nil }

        let sampleStartY = (height * 2) / 3
        let sampleHeight = height - sampleStartY

        guard let cropped = cgImage.cropping(
            to: CGRect(x: 0, y: sampleStartY, width: width, height: sampleHeight)
        ) else { return nil }

        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        var rawData = [UInt8](repeating: 0, count: sampleHeight * bytesPerRow)

        guard let context = CGContext(
            data: &rawData,
            width: width,
            height: sampleHeight,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        context.draw(cropped, in: CGRect(x: 0, y: 0, width: width, height: sampleHeight))

        var weightedR: CGFloat = 0
        var weightedG: CGFloat = 0
        var weightedB: CGFloat = 0
        var totalWeight: CGFloat = 0

        for i in stride(from: 0, to: rawData.count, by: bytesPerPixel) {
            let r = CGFloat(rawData[i]) / 255
            let g = CGFloat(rawData[i + 1]) / 255
            let b = CGFloat(rawData[i + 2]) / 255

            let maxC = max(r, g, b)
            let minC = min(r, g, b)
            let saturation = maxC == 0 ? 0 : (maxC - minC) / maxC

            let weight = saturation * saturation

            weightedR += r * weight
            weightedG += g * weight
            weightedB += b * weight
            totalWeight += weight
        }

        guard totalWeight > 0 else {
            var totalR: CGFloat = 0, totalG: CGFloat = 0, totalB: CGFloat = 0
            let pixelCount = CGFloat(width * sampleHeight)
            for i in stride(from: 0, to: rawData.count, by: bytesPerPixel) {
                totalR += CGFloat(rawData[i])
                totalG += CGFloat(rawData[i + 1])
                totalB += CGFloat(rawData[i + 2])
            }
            let r = (totalR / pixelCount / 255) * 0.5
            let g = (totalG / pixelCount / 255) * 0.5
            let b = (totalB / pixelCount / 255) * 0.5
            let (dr, dg, db) = darkenToMeetContrast(r: r, g: g, b: b, targetRatio: 5)
            return Color(red: dr, green: dg, blue: db)
        }

        var r = weightedR / totalWeight
        var g = weightedG / totalWeight
        var b = weightedB / totalWeight

        (r, g, b) = darkenToMeetContrast(r: r, g: g, b: b, targetRatio: 5)
        return Color(red: r, green: g, blue: b)
    }

    private func darkenToMeetContrast(r: CGFloat, g: CGFloat, b: CGFloat, targetRatio: CGFloat) -> (CGFloat, CGFloat, CGFloat) {
        var r = r, g = g, b = b
        func linearize(_ c: CGFloat) -> CGFloat {
            c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        func luminance(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> CGFloat {
            0.2126 * linearize(r) + 0.7152 * linearize(g) + 0.0722 * linearize(b)
        }
        func contrastAgainstWhite(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> CGFloat {
            (1.05) / (luminance(r, g, b) + 0.05)
        }
        while contrastAgainstWhite(r, g, b) < targetRatio {
            r *= 0.95; g *= 0.95; b *= 0.95
        }
        // Clamp brightness so light/desaturated images always produce a dark usable gradient
        let maxComponent = max(r, g, b)
        if maxComponent > 0.25 {
            let scale = 0.25 / maxComponent
            r *= scale; g *= scale; b *= scale
        }
        return (r, g, b)
    }
}


extension String {
    public var normalize: String {
        return self.underscoresToSpaces.precomposedStringWithCanonicalMapping
    }
}

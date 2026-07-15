import Foundation
import UIKit
import SwiftUI
import WMFData

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

    func isVisible(_ module: WMFForYouModule) -> Bool {
        switch module {
        case .basedOnInterests: return basedOnInterests
        case .becauseYouRead: return becauseYouRead
        case .continueReading: return continueReading
        }
    }
}

// MARK: - View models

@MainActor
public final class WMFForYouViewModel: ObservableObject {

    @Published public var pages: [WMFForYouPageViewModel] = []

    public init(response: WMFForYouResponse) {
        let topicPages = response.interestTopicRandomArticles.map {
            WMFForYouPageViewModel(module: .basedOnInterests, headerLabel: "Interest Topic: \($0.topic.displayName)", articles: $0.articles)
        }
        let relatedPages = response.interestPageRelatedArticles.map {
            WMFForYouPageViewModel(module: .basedOnInterests, headerLabel: "Interest Article: \($0.pageInterest.title)", articles: $0.articles)
        }
        let becauseYouReadPage: [WMFForYouPageViewModel] = response.becauseYouReadArticles.map {
            [WMFForYouPageViewModel(module: .becauseYouRead, headerLabel: "Because you read: \($0.recentlyRead.title)", articles: $0.articles)]
        } ?? []
        let continueReadingPage: [WMFForYouPageViewModel] = response.continueReadingArticles.map { continueReading in
            let continueCard = WMFForYouArticleCardViewModel(
                article: continueReading.continueReadingArticle,
                headerLabel: "Continue reading: \(continueReading.continueReadingArticle.title)"
            )
            let savedCards = continueReading.savedArticles.map {
                WMFForYouArticleCardViewModel(article: $0, headerLabel: "Saved article: \($0.title)")
            }
            return [WMFForYouPageViewModel(module: .continueReading, articleViewModels: [continueCard] + savedCards)]
        } ?? []
        self.pages = topicPages + relatedPages + becauseYouReadPage + continueReadingPage
    }
}

@MainActor
public final class WMFForYouPageViewModel: ObservableObject, Identifiable {

    public let id = UUID()
    public let module: WMFForYouModule
    public let articleViewModels: [WMFForYouArticleCardViewModel]

    public init(module: WMFForYouModule, headerLabel: String, articles: [WMFForYouArticle]) {
        self.module = module
        self.articleViewModels = articles.map {
            WMFForYouArticleCardViewModel(article: $0, headerLabel: headerLabel)
        }
    }

    public init(module: WMFForYouModule, articleViewModels: [WMFForYouArticleCardViewModel]) {
        self.module = module
        self.articleViewModels = articleViewModels
    }
}

@MainActor
public final class WMFForYouArticleCardViewModel: ObservableObject, Identifiable {

    public let id = UUID()
    public let headerLabel: String
    public let title: String
    public let project: WMFProject
    @Published public var description: String?
    @Published public var uiImage: UIImage?
    @Published public var sampledColor: Color?

    private var loadTask: Task<Void, Never>?

    public let hideKey: String

    public init(article: WMFForYouArticle, headerLabel: String) {
        self.headerLabel = headerLabel
        self.title = article.title
        self.project = article.project
        self.hideKey = "for_you_\(article.project.id)_\(article.title)"
    }

    public func load() {
        guard loadTask == nil else { return }
        loadTask = Task { [weak self] in
            guard let self else { return }
            guard let summary = try? await WMFArticleSummaryDataController.shared.fetchArticleSummary(project: project, title: title) else { return }
            self.description = summary.description
            guard let thumbnailURL = summary.thumbnailURL else { return }
            guard let data = try? await WMFImageDataController.shared.fetchImageData(url: thumbnailURL) else { return }
            let image = UIImage(data: data)
            self.uiImage = image
            if let image, let color = image.accessibleSampledColor() {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.sampledColor = color
                }
            }
        }
    }

    deinit {
        loadTask?.cancel()
    }
}

// MARK: - WCAG color sampling

private extension UIImage {
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

        var totalR: CGFloat = 0
        var totalG: CGFloat = 0
        var totalB: CGFloat = 0
        let pixelCount = CGFloat(width * sampleHeight)

        for i in stride(from: 0, to: rawData.count, by: bytesPerPixel) {
            totalR += CGFloat(rawData[i])
            totalG += CGFloat(rawData[i + 1])
            totalB += CGFloat(rawData[i + 2])
        }

        var r = totalR / pixelCount / 255
        var g = totalG / pixelCount / 255
        var b = totalB / pixelCount / 255

        (r, g, b) = darkenToMeetContrast(r: r, g: g, b: b, targetRatio: 4.5)

        return Color(red: r, green: g, blue: b)
    }
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
    return (r, g, b)
}

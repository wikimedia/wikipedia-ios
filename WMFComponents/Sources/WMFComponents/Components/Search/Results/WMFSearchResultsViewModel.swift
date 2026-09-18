import SwiftUI
import WMFData

@MainActor
public final class WMFSearchResultsViewModel: ObservableObject {

    public struct LocalizedStrings {
        let openActionTitle: String
        let openInNewTabActionTitle: String
        let openInBackgroundTabActionTitle: String
        let saveActionTitle: String
        let unsaveActionTitle: String
        let shareActionTitle: String
        let viewOnMapActionTitle: String
        let noResultsMessage: String
        let noInternetConnectionTitle: String

        public init(
            openActionTitle: String,
            openInNewTabActionTitle: String,
            openInBackgroundTabActionTitle: String,
            saveActionTitle: String,
            unsaveActionTitle: String,
            shareActionTitle: String,
            viewOnMapActionTitle: String,
            noResultsMessage: String,
            noInternetConnectionTitle: String
        ) {
            self.openActionTitle = openActionTitle
            self.openInNewTabActionTitle = openInNewTabActionTitle
            self.openInBackgroundTabActionTitle = openInBackgroundTabActionTitle
            self.saveActionTitle = saveActionTitle
            self.unsaveActionTitle = unsaveActionTitle
            self.shareActionTitle = shareActionTitle
            self.viewOnMapActionTitle = viewOnMapActionTitle
            self.noResultsMessage = noResultsMessage
            self.noInternetConnectionTitle = noInternetConnectionTitle
        }
    }

    public struct SearchResult: Identifiable, Equatable, Sendable {
        public let articleURL: URL
        public let pageTitle: String
        public let title: String
        public let titleHTML: String
        public let description: String?
        public let thumbnailURL: URL?
        public let isArticle: Bool
        public let hasLocation: Bool
        public let isSavable: Bool
        public var isSaved: Bool

        public var id: String {
            articleURL.absoluteString
        }

        var displayedDescription: String? {
            description?.components(separatedBy: "\n").first
        }

        public init(
            articleURL: URL,
            pageTitle: String,
            title: String,
            titleHTML: String,
            description: String?,
            thumbnailURL: URL?,
            isArticle: Bool = true,
            hasLocation: Bool = false,
            isSavable: Bool = true,
            isSaved: Bool = false
        ) {
            self.articleURL = articleURL
            self.pageTitle = pageTitle
            self.title = title
            self.titleHTML = titleHTML
            self.description = description
            self.thumbnailURL = thumbnailURL
            self.isArticle = isArticle
            self.hasLocation = hasLocation
            self.isSavable = isSavable
            self.isSaved = isSaved
        }
    }

    public enum EmptyState: Equatable, Sendable {
        case noResults
        case noInternetConnection
    }

    public enum ActionSource: Sendable {
        case swipe
        case contextMenu
    }

    public typealias ResultAction = @MainActor @Sendable (SearchResult, Int) -> Void
    public typealias SaveAction = @MainActor @Sendable (SearchResult, Int, ActionSource) -> Void
    public typealias ShareAction = @MainActor @Sendable (SearchResult, Int, CGRect?, ActionSource) -> Void
    public typealias IsSavedAction = @MainActor @Sendable (SearchResult) -> Bool
    public typealias SummaryProvider = @Sendable (WMFProject, String) async throws -> WMFArticleSummary

    @Published private(set) var results: [SearchResult] = []
    @Published private(set) var searchTerm: String?
    @Published private(set) var emptyState: EmptyState?
    @Published private(set) var project: WMFProject?
    @Published private(set) var isRightToLeft: Bool = false
    @Published public private(set) var entryPointViewModel: WMFSemanticSearchEntryPointViewModel?
    @Published private(set) var accessibilityFocusRequestID = 0

    static let entryPointAccessibilityID = "semantic-search-entry-point"
    @Published public var topPadding: CGFloat = 0
    @Published public var horizontalPadding: CGFloat = 16

    let localizedStrings: LocalizedStrings
    let noInternetConnectionImage: UIImage?
    var geometryFrames: [String: CGRect] = [:]

    private let isSavedAction: IsSavedAction
    private let tapAction: ResultAction
    private let openAction: ResultAction
    private let openInNewTabAction: ResultAction
    private let openInBackgroundTabAction: ResultAction
    private let openOnMapAction: ResultAction
    private let saveOrUnsaveAction: SaveAction
    private let shareAction: ShareAction
    private let summaryProvider: SummaryProvider

    public init(
        localizedStrings: LocalizedStrings,
        noInternetConnectionImage: UIImage?,
        isSavedAction: @escaping IsSavedAction,
        tapAction: @escaping ResultAction,
        openAction: @escaping ResultAction,
        openInNewTabAction: @escaping ResultAction,
        openInBackgroundTabAction: @escaping ResultAction,
        openOnMapAction: @escaping ResultAction,
        saveOrUnsaveAction: @escaping SaveAction,
        shareAction: @escaping ShareAction,
        summaryProvider: SummaryProvider? = nil
    ) {
        self.localizedStrings = localizedStrings
        self.noInternetConnectionImage = noInternetConnectionImage
        self.isSavedAction = isSavedAction
        self.tapAction = tapAction
        self.openAction = openAction
        self.openInNewTabAction = openInNewTabAction
        self.openInBackgroundTabAction = openInBackgroundTabAction
        self.openOnMapAction = openOnMapAction
        self.saveOrUnsaveAction = saveOrUnsaveAction
        self.shareAction = shareAction
        self.summaryProvider = summaryProvider ?? { project, title in
            try await WMFArticleSummaryDataController.shared.fetchArticleSummary(project: project, title: title)
        }
    }

    // MARK: - Public

    public func showResults(_ newResults: [SearchResult], searchTerm: String?, project: WMFProject?) {
        self.searchTerm = searchTerm
        self.project = project
        isRightToLeft = project?.isRTL ?? false
        results = newResults.map { result in
            var result = result
            result.isSaved = isSavedAction(result)
            return result
        }
        emptyState = results.isEmpty ? .noResults : nil
    }

    public func showEmptyState(_ state: EmptyState) {
        results = []
        emptyState = state
    }

    public func reset() {
        results = []
        searchTerm = nil
        emptyState = nil
    }

    public func showEntryPoint(_ viewModel: WMFSemanticSearchEntryPointViewModel) {
        entryPointViewModel = viewModel
    }

    public func hideEntryPoint() {
        entryPointViewModel = nil
    }

    var firstAccessibilityElementID: String? {
        entryPointViewModel != nil ? Self.entryPointAccessibilityID : results.first?.id
    }

    /// Moves VoiceOver to the first element of the list on the next layout pass. Used when the
    /// keyboard goes away, so the reader lands on the first result instead of the one closest to the
    /// search field.
    public func requestAccessibilityFocusOnFirstElement() {
        guard firstAccessibilityElementID != nil else { return }
        accessibilityFocusRequestID += 1
    }

    public func refreshSavedStates() {
        var didChange = false
        let refreshedResults = results.map { result in
            var result = result
            let isSaved = isSavedAction(result)
            if result.isSaved != isSaved {
                result.isSaved = isSaved
                didChange = true
            }
            return result
        }
        if didChange {
            results = refreshedResults
        }
    }

    // MARK: - Internal

    var languageCode: String? {
        guard case .wikipedia(let language) = project else { return nil }
        return language.languageCode
    }

    func accessibilityText(_ text: String) -> AttributedString {
        var attributedText = AttributedString(text)
        attributedText.languageIdentifier = languageCode
        return attributedText
    }

    func attributedTitle(for result: SearchResult, styles: HtmlUtils.Styles, boldFont: UIFont) -> AttributedString {
        var attributedTitle = (try? HtmlUtils.attributedStringFromHtml(result.titleHTML, styles: styles)) ?? AttributedString(result.titleHTML)

        if let searchTerm, !searchTerm.isEmpty,
           let range = attributedTitle.range(of: searchTerm, options: .caseInsensitive) {
            attributedTitle[range].font = boldFont
        }
        attributedTitle.languageIdentifier = languageCode
        return attributedTitle
    }

    func previewViewModel(for result: SearchResult) -> WMFArticlePreviewViewModel {
        WMFArticlePreviewViewModel(
            url: result.articleURL,
            titleHtml: result.title,
            description: result.displayedDescription,
            imageURL: result.thumbnailURL,
            isSaved: result.isSaved,
            snippet: nil
        )
    }

    func loadPreviewViewModel(for result: SearchResult) async -> WMFArticlePreviewViewModel {
        guard let project, let summary = try? await summaryProvider(project, result.pageTitle) else {
            return previewViewModel(for: result)
        }

        return WMFArticlePreviewViewModel(
            url: result.articleURL,
            titleHtml: result.title,
            description: summary.description ?? result.displayedDescription,
            imageURL: summary.thumbnailURL ?? result.thumbnailURL,
            isSaved: result.isSaved,
            snippet: summary.extract
        )
    }

    func loadImage(url: URL?) async -> UIImage? {
        guard let url,
              let data = try? await WMFImageDataController.shared.fetchImageData(url: url),
              let image = UIImage(data: data) else {
            return nil
        }

        guard let faceUnitRect = try? await WMFFaceDetectionCache.shared.faceBounds(in: image, for: url) else {
            return image
        }

        return Self.cropped(image, toSquareAround: faceUnitRect)
    }

    nonisolated static func squareCropRect(imageSize: CGSize, faceUnitRect: CGRect) -> CGRect {
        let side = min(imageSize.width, imageSize.height)
        let faceCenter = CGPoint(x: faceUnitRect.midX * imageSize.width, y: faceUnitRect.midY * imageSize.height)
        let x = min(max(0, faceCenter.x - side / 2), imageSize.width - side)
        let y = min(max(0, faceCenter.y - side / 2), imageSize.height - side)

        return CGRect(x: x, y: y, width: side, height: side)
    }

    private nonisolated static func cropped(_ image: UIImage, toSquareAround faceUnitRect: CGRect) -> UIImage {
        guard image.imageOrientation == .up, let cgImage = image.cgImage else {
            return image
        }
        let pixelSize = CGSize(width: cgImage.width, height: cgImage.height)
        let cropRect = squareCropRect(imageSize: pixelSize, faceUnitRect: faceUnitRect)
        guard let croppedCGImage = cgImage.cropping(to: cropRect) else {
            return image
        }

        return UIImage(cgImage: croppedCGImage, scale: image.scale, orientation: .up)
    }

    func tap(_ result: SearchResult) {
        guard let index = index(of: result) else { return }

        tapAction(result, index)
    }

    func open(_ result: SearchResult) {
        guard let index = index(of: result) else { return }

        openAction(result, index)
    }

    func openInNewTab(_ result: SearchResult) {
        guard let index = index(of: result) else { return }

        openInNewTabAction(result, index)
    }

    func openInBackgroundTab(_ result: SearchResult) {
        guard let index = index(of: result) else { return }

        openInBackgroundTabAction(result, index)
    }

    func openOnMap(_ result: SearchResult) {
        guard let index = index(of: result) else { return }

        openOnMapAction(result, index)
    }

    func saveOrUnsave(_ result: SearchResult, source: ActionSource) {
        guard let index = index(of: result) else { return }

        saveOrUnsaveAction(result, index, source)
    }

    func share(_ result: SearchResult, source: ActionSource) {
        guard let index = index(of: result) else { return }

        shareAction(result, index, geometryFrames[result.id], source)
    }

    private func index(of result: SearchResult) -> Int? {
        results.firstIndex(where: { $0.id == result.id })
    }
}

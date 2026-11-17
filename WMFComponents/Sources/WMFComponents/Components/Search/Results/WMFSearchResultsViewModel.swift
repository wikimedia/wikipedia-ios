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
        /// The start of the article's lead section. Only the semantic search interleaved treatment fetches it.
        public let extract: String?
        /// The section the extract comes from. Nil for the lead section.
        public let sectionTitle: String?
        public let thumbnailURL: URL?
        public let isArticle: Bool
        public let hasLocation: Bool
        public let isSavable: Bool
        public var isSaved: Bool
        /// Developer label of the semantic search interleaved experiment: which request gave the result. Nil unless the developer setting is on.
        public var sourceBadge: String?

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
            extract: String? = nil,
            sectionTitle: String? = nil,
            thumbnailURL: URL?,
            isArticle: Bool = true,
            hasLocation: Bool = false,
            isSavable: Bool = true,
            isSaved: Bool = false,
            sourceBadge: String? = nil
        ) {
            self.articleURL = articleURL
            self.pageTitle = pageTitle
            self.title = title
            self.titleHTML = titleHTML
            self.description = description
            self.extract = extract
            self.sectionTitle = sectionTitle
            self.thumbnailURL = thumbnailURL
            self.isArticle = isArticle
            self.hasLocation = hasLocation
            self.isSavable = isSavable
            self.isSaved = isSaved
            self.sourceBadge = sourceBadge
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
    public typealias AttributionProvider = @Sendable (WMFProject, String) async throws -> WMFSemanticSearchAttribution

    /// How the list draws its results. The semantic search interleaved treatment uses its own rows.
    public enum RowStyle: Equatable, Sendable {
        case standard
        case interleaved
    }

    @Published private(set) var results: [SearchResult] = []
    @Published private(set) var searchTerm: String?
    @Published private(set) var emptyState: EmptyState?
    @Published private(set) var project: WMFProject?
    @Published private(set) var rowStyle: RowStyle = .standard
    /// The view model of each card of the interleaved list, by result. The list keeps them, so a card that
    /// scrolls away and back neither asks for its counts again nor changes size. Not published: a card
    /// observes its own, so one that loads redraws that card only.
    private var interleavedRowViewModels: [String: WMFSearchResultInterleavedRowViewModel] = [:]
    @Published private(set) var isRightToLeft: Bool = false
    @Published public private(set) var semanticSearchEntryPointViewModel: WMFSemanticSearchEntryPointViewModel?
    @Published private(set) var accessibilityFocusRequestID = 0
    private var hasPendingAccessibilityFocusRequest = false

    static let semanticSearchEntryPointAccessibilityID = "semantic-search-entry-point"
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
    private let attributionProvider: AttributionProvider

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
        summaryProvider: SummaryProvider? = nil,
        attributionProvider: AttributionProvider? = nil
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
        self.attributionProvider = attributionProvider ?? { project, title in
            try await WMFSemanticSearchDataController.shared.fetchAttribution(title: title, project: project)
        }
    }

    // MARK: - Public

    public func showResults(_ newResults: [SearchResult], searchTerm: String?, project: WMFProject?, rowStyle: RowStyle = .standard) {
        self.searchTerm = searchTerm
        self.project = project
        self.rowStyle = rowStyle
        isRightToLeft = project?.isRTL ?? false
        results = newResults.map { result in
            var result = result
            result.isSaved = isSavedAction(result)
            return result
        }
        emptyState = results.isEmpty ? .noResults : nil
        interleavedRowViewModels = rowStyle == .interleaved ? makeInterleavedRowViewModels(for: results) : [:]
        fulfillPendingAccessibilityFocusRequest()
    }

    public func showEmptyState(_ state: EmptyState) {
        results = []
        interleavedRowViewModels = [:]
        emptyState = state
        hasPendingAccessibilityFocusRequest = false
    }

    public func reset() {
        results = []
        searchTerm = nil
        emptyState = nil
        rowStyle = .standard
        interleavedRowViewModels = [:]
    }

    public func showSemanticSearchEntryPoint(_ viewModel: WMFSemanticSearchEntryPointViewModel) {
        semanticSearchEntryPointViewModel = viewModel
        fulfillPendingAccessibilityFocusRequest()
    }

    public func hideSemanticSearchEntryPoint() {
        semanticSearchEntryPointViewModel = nil
    }

    /// A search with no lexical results still offers the semantic search entry point, so the list
    /// shows the card alone instead of the no results message.
    var showsSemanticSearchEntryPointInsteadOfEmptyState: Bool {
        emptyState == .noResults && semanticSearchEntryPointViewModel != nil
    }

    var firstAccessibilityElementID: String? {
        semanticSearchEntryPointViewModel != nil ? Self.semanticSearchEntryPointAccessibilityID : results.first?.id
    }

    /// Moves VoiceOver to the first element of the list on the next layout pass. Used when the
    /// keyboard goes away, so the reader lands on the first result instead of the one closest to the
    /// search field.
    public func requestAccessibilityFocusOnFirstElement() {
        guard firstAccessibilityElementID != nil else {
            hasPendingAccessibilityFocusRequest = true
            return
        }
        hasPendingAccessibilityFocusRequest = false
        accessibilityFocusRequestID += 1
    }

    private func fulfillPendingAccessibilityFocusRequest() {
        guard hasPendingAccessibilityFocusRequest, firstAccessibilityElementID != nil else { return }
        hasPendingAccessibilityFocusRequest = false
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

    /// The view model of the card of `result` in the interleaved list.
    func interleavedRowViewModel(for result: SearchResult) -> WMFSearchResultInterleavedRowViewModel {
        if let rowViewModel = interleavedRowViewModels[result.id] {
            return rowViewModel
        }
        return makeInterleavedRowViewModel(for: result)
    }

    private func makeInterleavedRowViewModels(for results: [SearchResult]) -> [String: WMFSearchResultInterleavedRowViewModel] {
        Dictionary(results.map { ($0.id, makeInterleavedRowViewModel(for: $0)) }, uniquingKeysWith: { first, _ in first })
    }

    private func makeInterleavedRowViewModel(for result: SearchResult) -> WMFSearchResultInterleavedRowViewModel {
        WMFSearchResultInterleavedRowViewModel(
            result: result,
            project: project,
            showsLastUpdatedInPlaceOfReferences: WMFSemanticSearchInterleavedDataController.shared.showsLastUpdatedInPlaceOfReferences(languageCode: languageCode),
            attributionProvider: attributionProvider)
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

        return image.croppedToSquare(around: faceUnitRect)
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

import UIKit
import WMFData

@MainActor
public final class WMFSemanticSearchViewModel: ObservableObject {

    public struct LocalizedStrings {
        public let title: String
        public let readInArticle: String
        public let emptyResults: String
        public let errorTitle: String

        public init(title: String, readInArticle: String, emptyResults: String, errorTitle: String) {
            self.title = title
            self.readInArticle = readInArticle
            self.emptyResults = emptyResults
            self.errorTitle = errorTitle
        }
    }

    public enum State {
        case loading
        case loaded
        case empty
        case error
    }

    public let searchTerm: String
    public let localizedStrings: LocalizedStrings

    /// Results requested per page. Defaults to `WMFSemanticSearchDataController.resultsPerPage`,
    /// which is the single lever for page size.
    public let resultsPerPage: Int

    @Published public private(set) var state: State = .loading
    @Published public private(set) var rows: [WMFSemanticSearchRowViewModel] = []
    @Published public private(set) var isLoadingNextPage = false

    /// Nil once the API stops handing back a continuation, meaning there is nothing left to page.
    private var continuation: WMFSemanticSearchContinuation?

    private let project: WMFProject
    private var fetchTask: Task<Void, Never>?

    public init(searchTerm: String, project: WMFProject, localizedStrings: LocalizedStrings, resultsPerPage: Int = WMFSemanticSearchDataController.resultsPerPage) {
        self.searchTerm = searchTerm
        self.project = project
        self.localizedStrings = localizedStrings
        self.resultsPerPage = resultsPerPage
    }

    deinit {
        fetchTask?.cancel()
    }

    public var canLoadMore: Bool {
        return continuation != nil
    }

    public func fetch() {
        fetchTask?.cancel()
        state = .loading
        rows = []
        continuation = nil
        isLoadingNextPage = false

        fetchTask = Task { [weak self] in
            guard let self else { return }

            do {
                let page = try await WMFSemanticSearchDataController.shared.fetchResults(searchTerm: self.searchTerm, project: self.project, limit: self.resultsPerPage)

                guard !Task.isCancelled else { return }

                guard !page.results.isEmpty else {
                    self.state = .empty
                    return
                }

                self.continuation = page.continuation
                self.rows = page.results.map { WMFSemanticSearchRowViewModel(result: $0) }
                self.state = .loaded
            } catch {
                guard !Task.isCancelled else { return }
                self.state = .error
            }
        }
    }

    /// Called as each row appears. Fetches the following page once the last row on screen is reached.
    public func loadNextPageIfNeeded(afterDisplaying row: WMFSemanticSearchRowViewModel) {
        guard row.id == rows.last?.id else { return }
        loadNextPage()
    }

    private func loadNextPage() {
        guard case .loaded = state,
              let continuation,
              !isLoadingNextPage else {
            return
        }

        isLoadingNextPage = true

        fetchTask = Task { [weak self] in
            guard let self else { return }

            defer { self.isLoadingNextPage = false }

            do {
                let page = try await WMFSemanticSearchDataController.shared.fetchResults(searchTerm: self.searchTerm, project: self.project, limit: self.resultsPerPage, continuation: continuation)

                guard !Task.isCancelled else { return }

                // The API can repeat pages it has already served, so only append new page IDs.
                let existingPageIDs = Set(self.rows.map { $0.id })
                let newRows = page.results
                    .filter { !existingPageIDs.contains($0.pageID) }
                    .map { WMFSemanticSearchRowViewModel(result: $0) }

                self.continuation = newRows.isEmpty ? nil : page.continuation
                self.rows.append(contentsOf: newRows)
            } catch {
                guard !Task.isCancelled else { return }

                // Leave the loaded rows in place and stop paging rather than blanking the list.
                self.continuation = nil
            }
        }
    }
}

/// One run of snippet text. Matches are the portions the search API wrapped in
/// `<span class="searchmatch">` and should be highlighted.
public struct WMFSemanticSearchSnippetSegment: Sendable, Identifiable {
    public let id = UUID()
    public let text: String
    public let isMatch: Bool
}

@MainActor
public final class WMFSemanticSearchRowViewModel: ObservableObject, Identifiable {

    /// Snippets are trimmed to roughly this many characters so every card stays a similar height.
    private static let maxSnippetLength = 260

    public let id: Int
    public let title: String
    public let sectionTitle: String?
    public let snippetSegments: [WMFSemanticSearchSnippetSegment]

    /// True when the snippet was trimmed, in which case the view appends an ellipsis.
    public let isSnippetTruncated: Bool

    @Published public private(set) var thumbnail: UIImage?

    private let thumbnailURL: URL?
    private var imageTask: Task<Void, Never>?
    private var hasStartedImageLoad = false

    init(result: WMFSemanticSearchResult) {
        self.id = result.pageID
        self.title = result.title
        self.sectionTitle = result.sectionTitle
        self.thumbnailURL = result.thumbnailURL

        let allSegments = Self.snippetSegments(html: result.snippetHTML)
        let truncatedSegments = Self.truncate(segments: allSegments, to: Self.maxSnippetLength)
        self.snippetSegments = truncatedSegments
        self.isSnippetTruncated = truncatedSegments.count != allSegments.count
            || truncatedSegments.last?.text.count != allSegments.last?.text.count
    }

    deinit {
        imageTask?.cancel()
    }

    /// Text shown beneath the snippet: "Title | Section title"
    public var breadcrumb: String {
        guard let sectionTitle, !sectionTitle.isEmpty else {
            return title
        }
        return "\(title) | \(sectionTitle)"
    }

    /// Called when the row's card appears, so thumbnail data is only fetched for rows the reader
    /// actually scrolls to. Safe to call repeatedly - the fetch starts at most once.
    public func loadImageIfNeeded() {
        guard !hasStartedImageLoad,
              let thumbnailURL else {
            return
        }

        hasStartedImageLoad = true

        imageTask = Task { [weak self] in
            guard let self else { return }
            guard let data = try? await WMFImageDataController.shared.fetchImageData(url: thumbnailURL) else { return }
            guard !Task.isCancelled else { return }
            self.thumbnail = UIImage(data: data)
        }
    }

    // MARK: - Snippet Parsing

    /// Splits the API snippet into plain text runs, flagging the `<span class="searchmatch">` ranges.
    private static func snippetSegments(html: String?) -> [WMFSemanticSearchSnippetSegment] {
        guard let html, !html.isEmpty else { return [] }

        let openTag = "<span class=\"searchmatch\">"
        let closeTag = "</span>"

        var segments: [WMFSemanticSearchSnippetSegment] = []
        var remainder = Substring(html)

        func append(_ text: Substring, isMatch: Bool) {
            guard !text.isEmpty else { return }
            let plainText = (try? HtmlUtils.stringFromHTML(String(text))) ?? String(text)
            guard !plainText.isEmpty else { return }
            segments.append(WMFSemanticSearchSnippetSegment(text: plainText, isMatch: isMatch))
        }

        while let openRange = remainder.range(of: openTag) {
            append(remainder[remainder.startIndex..<openRange.lowerBound], isMatch: false)

            let afterOpen = remainder[openRange.upperBound...]
            guard let closeRange = afterOpen.range(of: closeTag) else {
                remainder = afterOpen
                break
            }

            append(afterOpen[afterOpen.startIndex..<closeRange.lowerBound], isMatch: true)
            remainder = afterOpen[closeRange.upperBound...]
        }

        append(remainder, isMatch: false)

        return segments
    }

    /// Keeps segments until `maxLength` characters have been emitted, cutting the final segment
    /// at the last word boundary.
    private static func truncate(segments: [WMFSemanticSearchSnippetSegment], to maxLength: Int) -> [WMFSemanticSearchSnippetSegment] {
        var remainingLength = maxLength
        var truncated: [WMFSemanticSearchSnippetSegment] = []

        for segment in segments {
            guard remainingLength > 0 else { break }

            if segment.text.count <= remainingLength {
                truncated.append(segment)
                remainingLength -= segment.text.count
                continue
            }

            let cutoffIndex = segment.text.index(segment.text.startIndex, offsetBy: remainingLength)
            var partial = String(segment.text[segment.text.startIndex..<cutoffIndex])

            if let lastSpaceIndex = partial.lastIndex(of: " ") {
                partial = String(partial[partial.startIndex..<lastSpaceIndex])
            }

            truncated.append(WMFSemanticSearchSnippetSegment(text: partial, isMatch: segment.isMatch))
            remainingLength = 0
        }

        return truncated
    }
}

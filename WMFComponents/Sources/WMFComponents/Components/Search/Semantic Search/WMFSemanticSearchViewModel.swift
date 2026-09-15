import UIKit
import WMFData

@MainActor
public final class WMFSemanticSearchViewModel: ObservableObject {

    public struct LocalizedStrings {
        public let title: String
        public let readInArticle: String
        public let emptyResults: String
        public let errorTitle: String

        /// Format strings taking the formatted count, e.g. "%@ contributors".
        public let contributorCountFormat: String
        public let referenceCountFormat: String

        public init(title: String, readInArticle: String, emptyResults: String, errorTitle: String, contributorCountFormat: String, referenceCountFormat: String) {
            self.title = title
            self.readInArticle = readInArticle
            self.emptyResults = emptyResults
            self.errorTitle = errorTitle
            self.contributorCountFormat = contributorCountFormat
            self.referenceCountFormat = referenceCountFormat
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
                self.rows = page.results.map { WMFSemanticSearchRowViewModel(result: $0, project: self.project) }
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
                    .map { WMFSemanticSearchRowViewModel(result: $0, project: self.project) }

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

    /// Pipe-separated trail beneath the snippet. Starts as the article title alone and gains its
    /// section levels once the table of contents resolves, e.g. "Cat | Senses | Vision".
    @Published public private(set) var breadcrumb: String

    /// Number of editors who have contributed to the article. Nil until it loads, or if it fails.
    @Published public private(set) var contributorCount: Int?

    /// Number of references the article cites. Nil until it loads, or if it fails.
    @Published public private(set) var referenceCount: Int?

    private let project: WMFProject
    private let thumbnailURL: URL?
    private var imageTask: Task<Void, Never>?
    private var hasStartedImageLoad = false
    private var sectionTrailTask: Task<Void, Never>?
    private var hasStartedSectionTrailLoad = false
    private var statsTasks: [Task<Void, Never>] = []
    private var hasStartedStatsLoad = false

    init(result: WMFSemanticSearchResult, project: WMFProject) {
        self.id = result.pageID
        self.title = result.title
        self.sectionTitle = result.sectionTitle
        self.project = project
        self.thumbnailURL = result.thumbnailURL
        self.breadcrumb = result.title

        let allSegments = Self.snippetSegments(html: result.snippetHTML)
        let truncatedSegments = Self.truncate(segments: allSegments, to: Self.maxSnippetLength)
        self.snippetSegments = truncatedSegments
        self.isSnippetTruncated = truncatedSegments.count != allSegments.count
            || truncatedSegments.last?.text.count != allSegments.last?.text.count
    }

    deinit {
        imageTask?.cancel()
        sectionTrailTask?.cancel()
        statsTasks.forEach { $0.cancel() }
    }

    /// Called when the row's card appears. Loads the contributor and reference counts. The two
    /// calls are independent, so each count renders as soon as it arrives.
    /// Safe to call repeatedly - the fetches start at most once.
    public func loadStatsIfNeeded() {
        guard !hasStartedStatsLoad else { return }

        hasStartedStatsLoad = true

        let contributorsTask = Task { [weak self] in
            guard let self else { return }
            let count = try? await WMFPageStatsDataController.shared.fetchContributorCount(title: self.title, project: self.project)
            guard !Task.isCancelled else { return }
            self.contributorCount = count
        }

        let referencesTask = Task { [weak self] in
            guard let self else { return }
            let count = try? await WMFPageStatsDataController.shared.fetchReferenceCount(title: self.title, project: self.project)
            guard !Task.isCancelled else { return }
            self.referenceCount = count
        }

        statsTasks = [contributorsTask, referencesTask]
    }

    /// Called when the row's card appears. Resolves the section trail by fetching the article's
    /// table of contents, so the intermediary section of a nested subsection can be filled in.
    /// Safe to call repeatedly - the fetch starts at most once.
    public func loadSectionTrailIfNeeded() {
        guard !hasStartedSectionTrailLoad,
              let sectionTitle,
              !sectionTitle.isEmpty else {
            return
        }

        hasStartedSectionTrailLoad = true

        sectionTrailTask = Task { [weak self] in
            guard let self else { return }

            guard let sections = try? await WMFPageTOCDataController.shared.fetchSections(title: self.title, project: self.project) else {
                // Without the table of contents the search API's own section title is still better
                // than showing the article alone.
                self.breadcrumb = Self.trail(components: [self.title, sectionTitle])
                return
            }

            guard !Task.isCancelled else { return }

            self.breadcrumb = Self.breadcrumb(title: self.title, sectionTitle: sectionTitle, sections: sections)
        }
    }

    // MARK: - Section Trail

    /// Builds the pipe-separated trail: the article alone, article and section, or article, section
    /// and subsection. A nested section contributes its parent as the intermediary level.
    private static func breadcrumb(title: String, sectionTitle: String, sections: [WMFPageTOCSection]) -> String {

        guard let matchIndex = sections.firstIndex(where: { matches(section: $0, sectionTitle: sectionTitle) }) else {
            return trail(components: [title, sectionTitle])
        }

        let matchedSection = sections[matchIndex]
        let matchedLine = plainText(matchedSection.line)

        // The parent is the nearest preceding entry at a shallower level. For a subsection this is
        // the intermediary section the search API does not report.
        let parentLine = sections[..<matchIndex]
            .last(where: { $0.tocLevel < matchedSection.tocLevel })
            .map { plainText($0.line) }

        return trail(components: [title, parentLine, matchedLine])
    }

    private static func trail(components: [String?]) -> String {
        return components
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " | ")
    }

    private static func matches(section: WMFPageTOCSection, sectionTitle: String) -> Bool {
        let target = normalized(sectionTitle)
        return normalized(section.line) == target || normalized(section.anchor) == target
    }

    /// Anchors use underscores for spaces, and lines can carry HTML, so both are flattened before
    /// comparing against the search API's section title.
    private static func normalized(_ string: String) -> String {
        return plainText(string)
            .replacingOccurrences(of: "_", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    private static func plainText(_ string: String) -> String {
        return (try? HtmlUtils.stringFromHTML(string)) ?? string
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

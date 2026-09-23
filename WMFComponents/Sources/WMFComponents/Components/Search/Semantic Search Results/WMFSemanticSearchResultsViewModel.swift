import Foundation
import WMFData
import WMFNativeLocalizations

@MainActor
public final class WMFSemanticSearchResultsViewModel: ObservableObject {

    private enum ErrorKind {
        case general
        case rateLimited
        case backendUnavailable
    }

    enum State: Equatable {
        case loading
        case results
        case empty
        case error(WMFErrorViewModel)
    }

    public typealias ResultAction = @MainActor @Sendable (WMFSemanticSearchResult) -> Void
    public typealias Action = @MainActor @Sendable () -> Void

    let query: String
    let project: WMFProject
    let languageCode: String?

    /// The sheet lays out in the direction of the search language, not of the app language.
    var isRightToLeft: Bool {
        guard let languageCode else {
            return false
        }
        return Locale.Language(identifier: languageCode).characterDirection == .rightToLeft
    }

    @Published private(set) var state: State = .loading
    @Published private(set) var results: [WMFSemanticSearchResultViewModel] = []
    @Published private(set) var isLoadingMore = false

    static let maximumResultCount = 8

    private var nextOffset: Int?
    private var loadTask: Task<Void, Never>?
    private let readInArticleAction: ResultAction
    private let closeAction: Action

    private(set) lazy var betaLabel = CommonStrings.betaLabel(languageCode: languageCode)
    private(set) lazy var emptyTitle = WMFLocalizedString("search-semantic-results-empty-title", languageCode: languageCode, value: "No results for this search", comment: "Shown in the sheet of passages found inside articles when the search returns nothing.")
    private(set) lazy var retryTitle = CommonStrings.retryActionTitle
    private(set) lazy var generalErrorTitle = WMFLocalizedString("search-semantic-results-error-title", languageCode: languageCode, value: "Something went wrong", comment: "Title shown in the sheet of passages found inside articles when the search fails.")
    private(set) lazy var generalErrorSubtitle = WMFLocalizedString("search-semantic-results-error-subtitle", languageCode: languageCode, value: "Please try again.", comment: "Subtitle shown in the sheet of passages found inside articles when the search fails.")
    private(set) lazy var rateLimitedErrorTitle = WMFLocalizedString("search-semantic-results-rate-limited-title", languageCode: languageCode, value: "Too many searches", comment: "Title shown in the sheet of passages found inside articles when the reader searched too often.")
    private(set) lazy var rateLimitedErrorSubtitle = WMFLocalizedString("search-semantic-results-rate-limited-subtitle", languageCode: languageCode, value: "Wait a moment and try again.", comment: "Subtitle shown in the sheet of passages found inside articles when the reader searched too often.")
    private(set) lazy var backendUnavailableErrorTitle = WMFLocalizedString("search-semantic-results-unavailable-title", languageCode: languageCode, value: "Search is not available right now", comment: "Title shown in the sheet of passages found inside articles when the search service is down.")
    private(set) lazy var backendUnavailableErrorSubtitle = WMFLocalizedString("search-semantic-results-unavailable-subtitle", languageCode: languageCode, value: "Please try again later.", comment: "Subtitle shown in the sheet of passages found inside articles when the search service is down.")

    private lazy var resultLocalizedStrings = WMFSemanticSearchResultViewModel.LocalizedStrings(
        readInArticleTitle: WMFLocalizedString("search-semantic-results-read-in-article", languageCode: languageCode, value: "Read in article", comment: "Call to action at the end of a passage found inside an article. Opens the article at that passage."),
        contributorsFormat: WMFLocalizedString("search-semantic-results-contributors", languageCode: languageCode, value: "{{PLURAL:%1$d|%1$d contributor|%1$d contributors}}", comment: "Number of people who edited the article a passage comes from. %1$d is replaced with the number of contributors."),
        referencesFormat: WMFLocalizedString("search-semantic-results-references", languageCode: languageCode, value: "{{PLURAL:%1$d|%1$d reference|%1$d references}}", comment: "Number of references of the article a passage comes from. %1$d is replaced with the number of references."),
        lastUpdatedFormat: WMFLocalizedString("search-semantic-results-last-updated", languageCode: languageCode, value: "Last update %1$@", comment: "Date of the last edit of the article a passage comes from, shown where the reference count is not available. %1$@ is replaced with the date in the short numeric style of the device, e.g. 9/26/26.")
    )

    public init(query: String, project: WMFProject, readInArticleAction: @escaping ResultAction, closeAction: @escaping Action) {
        self.query = query
        self.project = project
        self.readInArticleAction = readInArticleAction
        self.closeAction = closeAction

        languageCode = project.languageCode
    }

    deinit {
        loadTask?.cancel()
    }

    // MARK: - Loading

    public func load() {
        cancel()
        state = .loading
        results = []
        nextOffset = nil
        loadTask = Task { [weak self] in
            await self?.fetch(offset: 0)
        }
    }

    func loadMoreIfNeeded(after item: WMFSemanticSearchResultViewModel) {
        guard state == .results,
              item.id == results.last?.id,
              let nextOffset,
              !isLoadingMore else {
            return
        }

        isLoadingMore = true
        loadTask = Task { [weak self] in
            await self?.fetch(offset: nextOffset)
        }
    }

    /// Stops the request in flight. Call it when the sheet is dismissed.
    public func cancel() {
        loadTask?.cancel()
        loadTask = nil
        isLoadingMore = false
    }

    private func fetch(offset: Int) async {
        do {
            let page = try await WMFSemanticSearchDataController.shared.fetchResults(query: query, project: project, offset: offset)
            guard !Task.isCancelled else { return }

            let newResults = page.results.map { WMFSemanticSearchResultViewModel(result: $0, project: project, localizedStrings: resultLocalizedStrings, readInArticleAction: readInArticleAction) }
            let allResults = offset == 0 ? newResults : results + newResults
            results = Array(allResults.prefix(Self.maximumResultCount))
            nextOffset = results.count < Self.maximumResultCount ? page.nextOffset : nil
            state = results.isEmpty ? .empty : .results
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled else { return }
            if offset == 0 {
                state = .error(errorViewModel(for: Self.errorKind(for: error)))
            }
        }

        isLoadingMore = false
        loadTask = nil
    }

    private static func errorKind(for error: Error) -> ErrorKind {
        switch error as? WMFSemanticSearchDataController.SearchError {
        case .rateLimited:
            return .rateLimited
        case .backendUnavailable:
            return .backendUnavailable
        default:
            return .general
        }
    }

    // MARK: - Presentation

    private func errorViewModel(for kind: ErrorKind) -> WMFErrorViewModel {
        WMFErrorViewModel(
            localizedStrings: WMFErrorViewModel.LocalizedStrings(
                title: errorTitle(for: kind),
                subtitle: errorSubtitle(for: kind),
                buttonTitle: retryTitle),
            image: nil)
    }

    private func errorTitle(for kind: ErrorKind) -> String {
        switch kind {
        case .general:
            return generalErrorTitle
        case .rateLimited:
            return rateLimitedErrorTitle
        case .backendUnavailable:
            return backendUnavailableErrorTitle
        }
    }

    private func errorSubtitle(for kind: ErrorKind) -> String {
        switch kind {
        case .general:
            return generalErrorSubtitle
        case .rateLimited:
            return rateLimitedErrorSubtitle
        case .backendUnavailable:
            return backendUnavailableErrorSubtitle
        }
    }

    // MARK: - Actions

    func close() {
        closeAction()
    }
}

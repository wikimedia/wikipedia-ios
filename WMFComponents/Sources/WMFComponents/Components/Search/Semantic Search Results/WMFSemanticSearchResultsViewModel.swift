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
    public typealias FeedbackAction = WMFSemanticSearchFeedbackViewModel.SubmitAction

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
    @Published private(set) var isFeedbackVisible = false

    /// The prompt above the passages asking whether the reader found what they were looking for.
    public private(set) lazy var feedbackViewModel = WMFSemanticSearchFeedbackViewModel(
        style: .inline,
        languageCode: languageCode,
        submitAction: { [weak self] rating, text in
            self?.submitFeedback(rating: rating, text: text)
        },
        textFieldFocusAction: feedbackTextFieldFocusAction
    )

    private var loadTask: Task<Void, Never>?
    private let readInArticleAction: ResultAction
    private let closeAction: Action
    private let feedbackAction: FeedbackAction?
    private let feedbackTextFieldFocusAction: Action?
    private let feedbackDelay: Duration
    private var feedbackTask: Task<Void, Never>?
    /// The sheet has had its one chance to ask: the reader submitted the banner, or an article
    /// opened from a passage took over asking. The banner doesn't come back and no other article asks.
    private var hasAskedForFeedback = false

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

    public init(query: String, project: WMFProject, readInArticleAction: @escaping ResultAction, closeAction: @escaping Action, feedbackAction: FeedbackAction? = nil, feedbackTextFieldFocusAction: Action? = nil, feedbackDelay: Duration = .seconds(3)) {
        self.query = query
        self.project = project
        self.readInArticleAction = readInArticleAction
        self.closeAction = closeAction
        self.feedbackAction = feedbackAction
        self.feedbackTextFieldFocusAction = feedbackTextFieldFocusAction
        self.feedbackDelay = feedbackDelay

        languageCode = project.languageCode
    }

    deinit {
        loadTask?.cancel()
        feedbackTask?.cancel()
    }

    // MARK: - Loading

    public func load() {
        cancel()
        state = .loading
        results = []
        loadTask = Task { [weak self] in
            await self?.fetch()
        }
    }

    /// Stops the request in flight. Call it when the sheet is dismissed.
    public func cancel() {
        loadTask?.cancel()
        loadTask = nil
    }

    private func fetch() async {
        do {
            let response = try await WMFSemanticSearchDataController.shared.fetchResults(query: query, project: project)
            guard !Task.isCancelled else { return }

            let readInArticleAction: ResultAction = { [weak self] in self?.readInArticle($0) }
            results = response.results.map { WMFSemanticSearchResultViewModel(result: $0, project: project, localizedStrings: resultLocalizedStrings, readInArticleAction: readInArticleAction) }
            state = results.isEmpty ? .empty : .results
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled else { return }
            state = .error(errorViewModel(for: Self.errorKind(for: error)))
        }

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

    // MARK: - Feedback

    /// Shows the feedback prompt a moment after the sheet appears. Call it when the sheet appears.
    public func sheetDidAppear() {
        guard feedbackTask == nil, !hasAskedForFeedback else { return }

        feedbackTask = Task { [weak self, feedbackDelay] in
            try? await Task.sleep(for: feedbackDelay)
            guard !Task.isCancelled else { return }
            self?.isFeedbackVisible = true
        }
    }

    /// Call it when opening an article from a passage. Returns true when the reader neither
    /// answered the prompt nor started to, so the article should ask instead. In that case the
    /// sheet stops asking, so a reader who comes back to it and opens another passage isn't asked twice.
    public func handOffFeedbackIfIgnored() -> Bool {
        guard !hasAskedForFeedback, !feedbackViewModel.hasRated else { return false }

        hasAskedForFeedback = true
        isFeedbackVisible = false
        feedbackTask?.cancel()
        return true
    }

    private func submitFeedback(rating: WMFSemanticSearchFeedbackViewModel.Rating, text: String?) {
        hasAskedForFeedback = true
        isFeedbackVisible = false
        feedbackAction?(rating, text)
        WMFToastPresenter.shared.show(WMFToastConfig(title: feedbackViewModel.thanksToastTitle))
    }

    // MARK: - Actions

    /// While the reader types feedback, a tap on a passage only puts the keyboard away, so a
    /// tap meant to leave the text field doesn't open the article and lose the draft.
    private func readInArticle(_ result: WMFSemanticSearchResult) {
        guard !feedbackViewModel.isTextFieldFocused else {
            feedbackViewModel.isTextFieldFocused = false
            return
        }
        readInArticleAction(result)
    }

    func close() {
        closeAction()
    }
}

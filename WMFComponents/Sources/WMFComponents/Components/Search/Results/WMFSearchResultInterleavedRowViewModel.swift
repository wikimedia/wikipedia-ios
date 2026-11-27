import SwiftUI
import WMFData
import WMFNativeLocalizations

/// One result of the semantic search interleaved treatment, drawn as a card. It holds what the card says and
/// the attribution counts of its article. Each card has its own, so a count that arrives redraws that card only.
@MainActor
final class WMFSearchResultInterleavedRowViewModel: ObservableObject {

    typealias SearchResult = WMFSearchResultsViewModel.SearchResult

    struct LocalizedStrings {
        let readInArticleTitle: String
        let contributorsFormat: String
        let referencesFormat: String
        let lastUpdatedFormat: String
        let leadSectionTitle: String
        let feedbackQuestion: String
        let thumbsUpAccessibilityLabel: String
        let thumbsDownAccessibilityLabel: String

        /// The strings the card shares with the semantic search sheet come from it, so each is defined once.
        static func forLanguage(_ languageCode: String?) -> LocalizedStrings {
            let sheetStrings = WMFSemanticSearchResultViewModel.LocalizedStrings.forLanguage(languageCode)
            return LocalizedStrings(
                readInArticleTitle: sheetStrings.readInArticleTitle,
                contributorsFormat: sheetStrings.contributorsFormat,
                referencesFormat: sheetStrings.referencesFormat,
                lastUpdatedFormat: sheetStrings.lastUpdatedFormat,
                leadSectionTitle: WMFLocalizedString("search-interleaved-results-lead-section", languageCode: languageCode, value: "Lead", comment: "Names the lead section of an article, the text before its first heading, on a search result that shows the start of the article. Shown with an arrow icon, where a result from a later section shows that section's title."),
                feedbackQuestion: WMFLocalizedString("search-interleaved-results-feedback-question", languageCode: languageCode, value: "Is this result relevant?", comment: "Question in the feedback row at the bottom of a search result card. The reader answers it with the thumbs up and thumbs down buttons next to it."),
                thumbsUpAccessibilityLabel: WMFLocalizedString("search-interleaved-results-feedback-thumbs-up-accessibility", languageCode: languageCode, value: "Yes", comment: "Accessibility label of the thumbs up button in the feedback row of a search result card. Answers the question whether the result is relevant."),
                thumbsDownAccessibilityLabel: WMFLocalizedString("search-interleaved-results-feedback-thumbs-down-accessibility", languageCode: languageCode, value: "No", comment: "Accessibility label of the thumbs down button in the feedback row of a search result card. Answers the question whether the result is relevant.")
            )
        }
    }

    /// Where the contributor and reference counts of the article are. `loaded(nil)` is a request that failed or an article without the signals.
    enum AttributionLoadState: Equatable {
        case loading
        case loaded(WMFSemanticSearchAttribution?)
    }

    /// Returns true when the answer is sent. When it returns false, the card stays open for another try.
    typealias RatingAction = @MainActor @Sendable (SearchResult, WMFSemanticSearchFeedbackViewModel.Rating) -> Bool

    let result: SearchResult
    let localizedStrings: LocalizedStrings

    @Published private(set) var attributionState: AttributionLoadState = .loading
    /// The answer of the reader. A card takes one answer, and it does not change.
    @Published private(set) var rating: WMFSemanticSearchFeedbackViewModel.Rating?

    private let ratingAction: RatingAction
    private let project: WMFProject?
    private let languageCode: String?
    private let showsLastUpdatedInPlaceOfReferences: Bool
    private let attributionProvider: WMFSearchResultsViewModel.AttributionProvider

    init(
        result: SearchResult,
        project: WMFProject?,
        showsLastUpdatedInPlaceOfReferences: Bool,
        attributionProvider: @escaping WMFSearchResultsViewModel.AttributionProvider,
        attributionState: AttributionLoadState = .loading,
        ratingAction: @escaping RatingAction = { _, _ in true },
        localizedStrings: LocalizedStrings? = nil
    ) {
        self.result = result
        self.ratingAction = ratingAction
        self.project = project
        self.languageCode = project?.languageCode
        self.showsLastUpdatedInPlaceOfReferences = showsLastUpdatedInPlaceOfReferences
        self.attributionProvider = attributionProvider
        self.attributionState = attributionState
        self.localizedStrings = localizedStrings ?? LocalizedStrings.forLanguage(project?.languageCode)
    }

    // MARK: - Loading

    /// Asks for the counts once. A card that scrolls away cancels the request, and a cancelled request is
    /// not kept, so the card asks again when it comes back. A loaded card never asks again.
    func loadAttribution() async {
        guard case .loading = attributionState, let project else { return }

        let attribution = try? await attributionProvider(project, result.pageTitle)
        guard !Task.isCancelled else { return }

        attributionState = .loaded(attribution)
    }

    // MARK: - Feedback

    /// Takes the first answer of the reader and passes it on. Later answers are ignored, so a card sends one answer.
    func rate(_ newRating: WMFSemanticSearchFeedbackViewModel.Rating) {
        guard rating == nil, ratingAction(result, newRating) else { return }

        rating = newRating
    }

    // MARK: - Presentation

    /// The section the extract comes from. A result without one comes from the lead section.
    var displayedSectionTitle: String {
        guard let sectionTitle = result.sectionTitle, !sectionTitle.isEmpty else {
            return localizedStrings.leadSectionTitle
        }
        return sectionTitle
    }

    private var loadedAttribution: WMFSemanticSearchAttribution? {
        guard case .loaded(let attribution) = attributionState else { return nil }
        return attribution
    }

    var contributorsText: String? {
        loadedAttribution?.contributorCount.map { String.localizedStringWithFormat(localizedStrings.contributorsFormat, $0) }
    }

    /// Not shown on the wikis that show the last update instead.
    var referencesText: String? {
        guard !showsLastUpdatedInPlaceOfReferences else { return nil }

        return loadedAttribution?.referenceCount.map { String.localizedStringWithFormat(localizedStrings.referencesFormat, $0) }
    }

    /// The second figure on the wikis that show the last update instead of the reference count: month and year, e.g. `09/2026`.
    var lastUpdatedText: String? {
        lastUpdatedDate.map { String.localizedStringWithFormat(localizedStrings.lastUpdatedFormat, DateFormatter.monthYearNumericFormatter.string(from: $0)) }
    }

    /// The same month and year spelled out, so VoiceOver does not read the numeric form.
    private var lastUpdatedAccessibilityText: String? {
        lastUpdatedDate.map { String.localizedStringWithFormat(localizedStrings.lastUpdatedFormat, DateFormatter.monthYearSpelledOutFormatter.string(from: $0)) }
    }

    private var lastUpdatedDate: Date? {
        guard showsLastUpdatedInPlaceOfReferences else { return nil }

        return loadedAttribution?.lastUpdated
    }

    /// While the counts load the row keeps its space. Once they are in, a card with none of them
    /// gives the space back, and a figure that is missing is left out.
    var showsAttributionRow: Bool {
        switch attributionState {
        case .loading:
            return true
        case .loaded:
            return contributorsText != nil || referencesText != nil || lastUpdatedText != nil
        }
    }

    /// What VoiceOver reads for the card, as one text tagged with the language of the wiki, so a voice for
    /// that language reads all of it. It is one label because the language of a label can be lost when
    /// VoiceOver merges the labels of the children.
    var accessibilityText: AttributedString {
        var parts = [result.title]
        if let description = result.description {
            parts.append(description)
        }
        parts.append(displayedSectionTitle)
        if let extract = result.extract, !extract.isEmpty {
            parts.append(extract)
        }
        parts.append(localizedStrings.readInArticleTitle)
        parts.append(contentsOf: [contributorsText, referencesText, lastUpdatedAccessibilityText].compactMap { $0 })

        var text = AttributedString(parts.joined(separator: ", "))
        text.languageIdentifier = languageCode
        return text
    }
}

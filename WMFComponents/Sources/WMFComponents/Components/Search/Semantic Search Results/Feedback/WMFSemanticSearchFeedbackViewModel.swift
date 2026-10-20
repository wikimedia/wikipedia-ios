import Foundation
import WMFNativeLocalizations

/// Asks the reader whether the semantic search found what they were looking for. Shared by the
/// inline banner above the passages and the card shown in the article opened from a passage.
@MainActor
public final class WMFSemanticSearchFeedbackViewModel: ObservableObject {

    public enum Style {
        /// Banner in the list of passages. The text field appears once the reader rates.
        case inline
        /// Card in the article, with a title and a close button. The text field shows right away.
        case card
    }

    public enum Rating: String, Sendable {
        case positive
        case negative
    }

    public typealias SubmitAction = @MainActor @Sendable (Rating, String?) -> Void
    public typealias Action = @MainActor @Sendable () -> Void

    let style: Style
    let languageCode: String?

    @Published private(set) var rating: Rating?
    @Published var text = ""
    /// Mirrors the focus of the text field, so the keyboard is up exactly while this is true.
    @Published var isTextFieldFocused = false {
        didSet {
            if isTextFieldFocused, !oldValue {
                textFieldFocusAction?()
            }
        }
    }

    /// The reader tapped a thumb. An inline prompt the reader rated counts as answered.
    public var hasRated: Bool {
        rating != nil
    }

    var isTextFieldVisible: Bool {
        style == .card || hasRated
    }

    var canSubmit: Bool {
        hasRated
    }

    private let submitAction: SubmitAction
    private let closeAction: Action?
    private let textFieldFocusAction: Action?

    private(set) lazy var title = WMFLocalizedString("semantic-search-feedback-title", languageCode: languageCode, value: "Feedback", comment: "Title of the card that asks for feedback on the search, shown in an article opened from a passage found by the search.")
    private(set) lazy var question = WMFLocalizedString("semantic-search-feedback-question", languageCode: languageCode, value: "Found what you were looking for?", comment: "Question asking whether the passages found by the search were useful. Followed by thumbs up and thumbs down buttons.")
    private(set) lazy var placeholder = WMFLocalizedString("semantic-search-feedback-placeholder", languageCode: languageCode, value: "Tell us more (optional)", comment: "Placeholder of the optional text field in the feedback on the search.")
    private(set) lazy var submitTitle = WMFLocalizedString("semantic-search-feedback-submit", languageCode: languageCode, value: "Submit", comment: "Title of the button that sends the feedback on the search.")
    private(set) lazy var thumbsUpAccessibilityLabel = WMFLocalizedString("semantic-search-feedback-thumbs-up-accessibility", languageCode: languageCode, value: "Yes", comment: "Accessibility label of the thumbs up button in the feedback on the search. Answers the question whether the reader found what they were looking for.")
    private(set) lazy var thumbsDownAccessibilityLabel = WMFLocalizedString("semantic-search-feedback-thumbs-down-accessibility", languageCode: languageCode, value: "No", comment: "Accessibility label of the thumbs down button in the feedback on the search. Answers the question whether the reader found what they were looking for.")
    private(set) lazy var closeAccessibilityLabel = CommonStrings.closeButtonAccessibilityLabel
    private(set) lazy var thanksToastTitle = Self.thanksToastTitle(languageCode: languageCode)

    public static func thanksToastTitle(languageCode: String? = nil) -> String {
        WMFLocalizedString("semantic-search-feedback-thanks", languageCode: languageCode, value: "Thanks for your feedback", comment: "Toast shown after the reader sends feedback on the search.")
    }

    public init(style: Style, languageCode: String? = nil, submitAction: @escaping SubmitAction, closeAction: Action? = nil, textFieldFocusAction: Action? = nil) {
        self.style = style
        self.languageCode = languageCode
        self.submitAction = submitAction
        self.closeAction = closeAction
        self.textFieldFocusAction = textFieldFocusAction
    }

    func rate(_ rating: Rating) {
        self.rating = rating
    }

    func submit() {
        guard let rating else { return }

        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        submitAction(rating, trimmedText.isEmpty ? nil : trimmedText)
    }

    func close() {
        closeAction?()
    }
}

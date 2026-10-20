import Foundation

public final class WMFSurveyViewModel {

    public struct LocalizedStrings {
        let title: String
        let cancel: String
        let submit: String
        let heading: String?
        let subtitle: String
        let instructions: String?

        let otherPlaceholder: String
        let characterLimitErrorText: String?

        public init(
            title: String,
            cancel: String,
            submit: String,
            heading: String? = nil,
            subtitle: String,
            instructions: String?,
            otherPlaceholder: String,
            characterLimitErrorText: String? = nil
        ) {
            self.title = title
            self.cancel = cancel
            self.submit = submit
            self.heading = heading
            self.subtitle = subtitle
            self.instructions = instructions
            self.otherPlaceholder = otherPlaceholder
            self.characterLimitErrorText = characterLimitErrorText
        }
    }

    public struct OptionViewModel: Hashable, Identifiable {
        public let id = UUID()
        public let text: String
        public let apiIdentifer: String

        public func hash(into hasher: inout Hasher) {
            hasher.combine(apiIdentifer)
        }

        public static func == (lhs: WMFSurveyViewModel.OptionViewModel, rhs: WMFSurveyViewModel.OptionViewModel) -> Bool {
            return lhs.apiIdentifer == rhs.apiIdentifer
        }

        public init(text: String, apiIdentifer: String) {
            self.text = text
            self.apiIdentifer = apiIdentifer
        }
    }

    public enum SelectionType {
        case multi
        case single
    }

    let localizedStrings: LocalizedStrings
    let options: [OptionViewModel]
    let selectionType: SelectionType
    let shouldShowMultilineText: Bool
    let otherTextCharacterLimit: Int?

    public init(
        localizedStrings: LocalizedStrings,
        options: [OptionViewModel],
        selectionType: SelectionType,
        shouldShowMultilineText: Bool = false,
        otherTextCharacterLimit: Int? = nil
    ) {
        self.localizedStrings = localizedStrings
        self.options = options
        self.selectionType = selectionType
        self.shouldShowMultilineText = shouldShowMultilineText
        self.otherTextCharacterLimit = otherTextCharacterLimit
    }

}

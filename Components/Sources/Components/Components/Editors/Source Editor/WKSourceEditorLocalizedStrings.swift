import Foundation

public struct WKSourceEditorLocalizedStrings {
    static var current: WKSourceEditorLocalizedStrings!

    let inputViewTextFormatting: String
    let inputViewStyle: String
    let inputViewClearFormatting: String
    let inputViewParagraph: String
    let inputViewHeading: String
    let inputViewSubheading1: String
    let inputViewSubheading2: String
    let inputViewSubheading3: String
    let inputViewSubheading4: String
    let findReplaceTypeSingle: String
    let findReplaceTypeAll: String
    let findReplaceWith: String

    let accessibilityLabelButtonFormatText: String
    let accessibilityLabelButtonCitation: String
    let accessibilityLabelButtonCitationSelected: String
    let accessibilityLabelButtonLink: String
    let accessibilityLabelButtonLinkSelected: String
    let accessibilityLabelButtonTemplate: String
    let accessibilityLabelButtonTemplateSelected: String
    let accessibilityLabelButtonMedia: String
    let accessibilityLabelButtonFind: String
    let accessibilityLabelButtonListUnordered: String
    let accessibilityLabelButtonListUnorderedSelected: String
    let accessibilityLabelButtonListOrdered: String
    let accessibilityLabelButtonListOrderedSelected: String
    let accessibilityLabelButtonInceaseIndent: String
    let accessibilityLabelButtonDecreaseIndent: String
    let accessibilityLabelButtonCursorUp: String
    let accessibilityLabelButtonCursorDown: String
    let accessibilityLabelButtonCursorLeft: String
    let accessibilityLabelButtonCursorRight: String

    let accessibilityLabelButtonBold: String
    let accessibilityLabelButtonBoldSelected: String
    let accessibilityLabelButtonItalics: String
    let accessibilityLabelButtonItalicsSelected: String
    let accessibilityLabelButtonClearFormatting: String
    let accessibilityLabelButtonShowMore: String

    let accessibilityLabelButtonComment: String
    let accessibilityLabelButtonCommentSelected: String
    let accessibilityLabelButtonSuperscript: String
    let accessibilityLabelButtonSuperscriptSelected: String
    let accessibilityLabelButtonSubscript: String
    let accessibilityLabelButtonSubscriptSelected: String
    let accessibilityLabelButtonUnderline: String
    let accessibilityLabelButtonUnderlineSelected: String
    let accessibilityLabelButtonStrikethrough: String
    let accessibilityLabelButtonStrikethroughSelected: String

    let accessibilityLabelButtonCloseMainInputView: String
    let accessibilityLabelButtonCloseHeaderSelectInputView: String

    let accessibilityLabelFindTextField: String
    let accessibilityLabelFindButtonClear: String
    let accessibilityLabelFindButtonClose: String
    let accessibilityLabelFindButtonNext: String
    let accessibilityLabelFindButtonPrevious: String
    let accessibilityLabelReplaceTextField: String
    let accessibilityLabelReplaceButtonClear: String
    let accessibilityLabelReplaceButtonPerformFormat: String
    let accessibilityLabelReplaceButtonSwitchFormat: String
    let accessibilityLabelReplaceTypeSingle: String
    let accessibilityLabelReplaceTypeAll: String

    public init(inputViewTextFormatting: String, inputViewStyle: String, inputViewClearFormatting: String, inputViewParagraph: String, inputViewHeading: String, inputViewSubheading1: String, inputViewSubheading2: String, inputViewSubheading3: String, inputViewSubheading4: String, findReplaceTypeSingle: String, findReplaceTypeAll: String, findReplaceWith: String, accessibilityLabelButtonFormatText: String, accessibilityLabelButtonCitation: String, accessibilityLabelButtonCitationSelected: String, accessibilityLabelButtonLink: String, accessibilityLabelButtonLinkSelected: String, accessibilityLabelButtonTemplate: String, accessibilityLabelButtonTemplateSelected: String, accessibilityLabelButtonMedia: String, accessibilityLabelButtonFind: String, accessibilityLabelButtonListUnordered: String, accessibilityLabelButtonListUnorderedSelected: String, accessibilityLabelButtonListOrdered: String, accessibilityLabelButtonListOrderedSelected: String, accessibilityLabelButtonInceaseIndent: String, accessibilityLabelButtonDecreaseIndent: String, accessibilityLabelButtonCursorUp: String, accessibilityLabelButtonCursorDown: String, accessibilityLabelButtonCursorLeft: String, accessibilityLabelButtonCursorRight: String, accessibilityLabelButtonBold: String, accessibilityLabelButtonBoldSelected: String, accessibilityLabelButtonItalics: String, accessibilityLabelButtonItalicsSelected: String, accessibilityLabelButtonClearFormatting: String, accessibilityLabelButtonShowMore: String, accessibilityLabelButtonComment: String, accessibilityLabelButtonCommentSelected: String, accessibilityLabelButtonSuperscript: String, accessibilityLabelButtonSuperscriptSelected: String, accessibilityLabelButtonSubscript: String, accessibilityLabelButtonSubscriptSelected: String, accessibilityLabelButtonUnderline: String, accessibilityLabelButtonUnderlineSelected: String, accessibilityLabelButtonStrikethrough: String, accessibilityLabelButtonStrikethroughSelected: String, accessibilityLabelButtonCloseMainInputView: String, accessibilityLabelButtonCloseHeaderSelectInputView: String, accessibilityLabelFindTextField: String, accessibilityLabelFindButtonClear: String, accessibilityLabelFindButtonClose: String, accessibilityLabelFindButtonNext: String, accessibilityLabelFindButtonPrevious: String, accessibilityLabelReplaceTextField: String, accessibilityLabelReplaceButtonClear: String, accessibilityLabelReplaceButtonPerformFormat: String, accessibilityLabelReplaceButtonSwitchFormat: String, accessibilityLabelReplaceTypeSingle: String, accessibilityLabelReplaceTypeAll: String) {
        self.inputViewTextFormatting = inputViewTextFormatting
        self.inputViewStyle = inputViewStyle
        self.inputViewClearFormatting = inputViewClearFormatting
        self.inputViewParagraph = inputViewParagraph
        self.inputViewHeading = inputViewHeading
        self.inputViewSubheading1 = inputViewSubheading1
        self.inputViewSubheading2 = inputViewSubheading2
        self.inputViewSubheading3 = inputViewSubheading3
        self.inputViewSubheading4 = inputViewSubheading4
        self.findReplaceTypeSingle = findReplaceTypeSingle
        self.findReplaceTypeAll = findReplaceTypeAll
        self.findReplaceWith = findReplaceWith
        self.accessibilityLabelButtonFormatText = accessibilityLabelButtonFormatText
        self.accessibilityLabelButtonCitation = accessibilityLabelButtonCitation
        self.accessibilityLabelButtonCitationSelected = accessibilityLabelButtonCitationSelected
        self.accessibilityLabelButtonLink = accessibilityLabelButtonLink
        self.accessibilityLabelButtonLinkSelected = accessibilityLabelButtonLinkSelected
        self.accessibilityLabelButtonTemplate = accessibilityLabelButtonTemplate
        self.accessibilityLabelButtonTemplateSelected = accessibilityLabelButtonTemplateSelected
        self.accessibilityLabelButtonMedia = accessibilityLabelButtonMedia
        self.accessibilityLabelButtonFind = accessibilityLabelButtonFind
        self.accessibilityLabelButtonListUnordered = accessibilityLabelButtonListUnordered
        self.accessibilityLabelButtonListUnorderedSelected = accessibilityLabelButtonListUnorderedSelected
        self.accessibilityLabelButtonListOrdered = accessibilityLabelButtonListOrdered
        self.accessibilityLabelButtonListOrderedSelected = accessibilityLabelButtonListOrderedSelected
        self.accessibilityLabelButtonInceaseIndent = accessibilityLabelButtonInceaseIndent
        self.accessibilityLabelButtonDecreaseIndent = accessibilityLabelButtonDecreaseIndent
        self.accessibilityLabelButtonCursorUp = accessibilityLabelButtonCursorUp
        self.accessibilityLabelButtonCursorDown = accessibilityLabelButtonCursorDown
        self.accessibilityLabelButtonCursorLeft = accessibilityLabelButtonCursorLeft
        self.accessibilityLabelButtonCursorRight = accessibilityLabelButtonCursorRight
        self.accessibilityLabelButtonBold = accessibilityLabelButtonBold
        self.accessibilityLabelButtonBoldSelected = accessibilityLabelButtonBoldSelected
        self.accessibilityLabelButtonItalics = accessibilityLabelButtonItalics
        self.accessibilityLabelButtonItalicsSelected = accessibilityLabelButtonItalicsSelected
        self.accessibilityLabelButtonClearFormatting = accessibilityLabelButtonClearFormatting
        self.accessibilityLabelButtonShowMore = accessibilityLabelButtonShowMore
        self.accessibilityLabelButtonComment = accessibilityLabelButtonComment
        self.accessibilityLabelButtonCommentSelected = accessibilityLabelButtonCommentSelected
        self.accessibilityLabelButtonSuperscript = accessibilityLabelButtonSuperscript
        self.accessibilityLabelButtonSuperscriptSelected = accessibilityLabelButtonSuperscriptSelected
        self.accessibilityLabelButtonSubscript = accessibilityLabelButtonSubscript
        self.accessibilityLabelButtonSubscriptSelected = accessibilityLabelButtonSubscriptSelected
        self.accessibilityLabelButtonUnderline = accessibilityLabelButtonUnderline
        self.accessibilityLabelButtonUnderlineSelected = accessibilityLabelButtonUnderlineSelected
        self.accessibilityLabelButtonStrikethrough = accessibilityLabelButtonStrikethrough
        self.accessibilityLabelButtonStrikethroughSelected = accessibilityLabelButtonStrikethroughSelected
        self.accessibilityLabelButtonCloseMainInputView = accessibilityLabelButtonCloseMainInputView
        self.accessibilityLabelButtonCloseHeaderSelectInputView = accessibilityLabelButtonCloseHeaderSelectInputView
        self.accessibilityLabelFindTextField = accessibilityLabelFindTextField
        self.accessibilityLabelFindButtonClear = accessibilityLabelFindButtonClear
        self.accessibilityLabelFindButtonClose = accessibilityLabelFindButtonClose
        self.accessibilityLabelFindButtonNext = accessibilityLabelFindButtonNext
        self.accessibilityLabelFindButtonPrevious = accessibilityLabelFindButtonPrevious
        self.accessibilityLabelReplaceTextField = accessibilityLabelReplaceTextField
        self.accessibilityLabelReplaceButtonClear = accessibilityLabelReplaceButtonClear
        self.accessibilityLabelReplaceButtonPerformFormat = accessibilityLabelReplaceButtonPerformFormat
        self.accessibilityLabelReplaceButtonSwitchFormat = accessibilityLabelReplaceButtonSwitchFormat
        self.accessibilityLabelReplaceTypeSingle = accessibilityLabelReplaceTypeSingle
        self.accessibilityLabelReplaceTypeAll = accessibilityLabelReplaceTypeAll
    }
}

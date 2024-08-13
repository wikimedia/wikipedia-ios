import Foundation

public struct WMFSourceEditorLocalizedStrings {
    static var current: WMFSourceEditorLocalizedStrings!

    // visible strings
    let keyboardTextFormattingTitle: String
    let keyboardParagraph: String
    let keyboardHeading: String
    let keyboardSubheading1: String
    let keyboardSubheading2: String
    let keyboardSubheading3: String
    let keyboardSubheading4: String
    let findAndReplaceTitle: String
    let replaceTypeSingle: String
    let replaceTypeAll: String
    let replaceTextfieldPlaceholder: String
    let replaceTypeContextMenuTitle: String

    // Voice Over strings
    let toolbarOpenTextFormatMenuButtonAccessibility: String
    let toolbarReferenceButtonAccessibility: String
    let toolbarLinkButtonAccessibility: String
    let toolbarTemplateButtonAccessibility: String
    let toolbarImageButtonAccessibility: String
    let toolbarFindButtonAccessibility: String
    let toolbarExpandButtonAccessibility: String
    let toolbarListUnorderedButtonAccessibility: String
    let toolbarListOrderedButtonAccessibility: String
    let toolbarIndentIncreaseButtonAccessibility: String
    let toolbarIndentDecreaseButtonAccessibility: String
    let toolbarCursorUpButtonAccessibility: String
    let toolbarCursorDownButtonAccessibility: String
    let toolbarCursorPreviousButtonAccessibility: String
    let toolbarCursorNextButtonAccessibility: String
    let toolbarBoldButtonAccessibility: String
    let toolbarItalicsButtonAccessibility: String
    
    let keyboardCloseTextFormatMenuButtonAccessibility: String
    let keyboardBoldButtonAccessibility: String
    let keyboardItalicsButtonAccessibility: String
    let keyboardUnderlineButtonAccessibility: String
    let keyboardStrikethroughButtonAccessibility: String
    let keyboardReferenceButtonAccessibility: String
    let keyboardLinkButtonAccessibility: String
    let keyboardListUnorderedButtonAccessibility: String
    let keyboardListOrderedButtonAccessibility: String
    let keyboardIndentIncreaseButtonAccessibility: String
    let keyboardIndentDecreaseButtonAccessibility: String
    let keyboardSuperscriptButtonAccessibility: String
    let keyboardSubscriptButtonAccessibility: String
    let keyboardTemplateButtonAccessibility: String
    let keyboardCommentButtonAccessibility: String

    let wikitextEditorAccessibility: String
    let wikitextEditorLoadingAccessibility: String
    let findTextFieldAccessibility: String
    let findClearButtonAccessibility: String
    let findCurrentMatchInfoFormatAccessibility: String
    let findCurrentMatchInfoZeroResultsAccessibility: String
    let findCloseButtonAccessibility: String
    let findNextButtonAccessibility: String
    let findPreviousButtonAccessibility: String
    let replaceTextFieldAccessibility: String
    let replaceClearButtonAccessibility: String
    let replaceButtonAccessibilityFormat: String
    let replaceTypeButtonAccessibilityFormat: String
    let replaceTypeSingleAccessibility: String
    let replaceTypeAllAccessibility: String
    
    public init(keyboardTextFormattingTitle: String, keyboardParagraph: String, keyboardHeading: String, keyboardSubheading1: String, keyboardSubheading2: String, keyboardSubheading3: String, keyboardSubheading4: String, findAndReplaceTitle: String, replaceTypeSingle: String, replaceTypeAll: String, replaceTextfieldPlaceholder: String, replaceTypeContextMenuTitle: String, toolbarOpenTextFormatMenuButtonAccessibility: String, toolbarReferenceButtonAccessibility: String, toolbarLinkButtonAccessibility: String, toolbarTemplateButtonAccessibility: String, toolbarImageButtonAccessibility: String, toolbarFindButtonAccessibility: String, toolbarExpandButtonAccessibility: String, toolbarListUnorderedButtonAccessibility: String, toolbarListOrderedButtonAccessibility: String, toolbarIndentIncreaseButtonAccessibility: String, toolbarIndentDecreaseButtonAccessibility: String, toolbarCursorUpButtonAccessibility: String, toolbarCursorDownButtonAccessibility: String, toolbarCursorPreviousButtonAccessibility: String, toolbarCursorNextButtonAccessibility: String, toolbarBoldButtonAccessibility: String, toolbarItalicsButtonAccessibility: String, keyboardCloseTextFormatMenuButtonAccessibility: String, keyboardBoldButtonAccessibility: String, keyboardItalicsButtonAccessibility: String, keyboardUnderlineButtonAccessibility: String, keyboardStrikethroughButtonAccessibility: String, keyboardReferenceButtonAccessibility: String, keyboardLinkButtonAccessibility: String, keyboardListUnorderedButtonAccessibility: String, keyboardListOrderedButtonAccessibility: String, keyboardIndentIncreaseButtonAccessibility: String, keyboardIndentDecreaseButtonAccessibility: String, keyboardSuperscriptButtonAccessibility: String, keyboardSubscriptButtonAccessibility: String, keyboardTemplateButtonAccessibility: String, keyboardCommentButtonAccessibility: String, wikitextEditorAccessibility: String, wikitextEditorLoadingAccessibility: String, findTextFieldAccessibility: String, findClearButtonAccessibility: String, findCurrentMatchInfoFormatAccessibility: String, findCurrentMatchInfoZeroResultsAccessibility: String, findCloseButtonAccessibility: String, findNextButtonAccessibility: String, findPreviousButtonAccessibility: String, replaceTextFieldAccessibility: String, replaceClearButtonAccessibility: String, replaceButtonAccessibilityFormat: String, replaceTypeButtonAccessibilityFormat: String, replaceTypeSingleAccessibility: String, replaceTypeAllAccessibility: String) {
        self.keyboardTextFormattingTitle = keyboardTextFormattingTitle
        self.keyboardParagraph = keyboardParagraph
        self.keyboardHeading = keyboardHeading
        self.keyboardSubheading1 = keyboardSubheading1
        self.keyboardSubheading2 = keyboardSubheading2
        self.keyboardSubheading3 = keyboardSubheading3
        self.keyboardSubheading4 = keyboardSubheading4
        self.findAndReplaceTitle = findAndReplaceTitle
        self.replaceTypeSingle = replaceTypeSingle
        self.replaceTypeAll = replaceTypeAll
        self.replaceTextfieldPlaceholder = replaceTextfieldPlaceholder
        self.replaceTypeContextMenuTitle = replaceTypeContextMenuTitle
        self.toolbarOpenTextFormatMenuButtonAccessibility = toolbarOpenTextFormatMenuButtonAccessibility
        self.toolbarReferenceButtonAccessibility = toolbarReferenceButtonAccessibility
        self.toolbarLinkButtonAccessibility = toolbarLinkButtonAccessibility
        self.toolbarTemplateButtonAccessibility = toolbarTemplateButtonAccessibility
        self.toolbarImageButtonAccessibility = toolbarImageButtonAccessibility
        self.toolbarFindButtonAccessibility = toolbarFindButtonAccessibility
        self.toolbarExpandButtonAccessibility = toolbarExpandButtonAccessibility
        self.toolbarListUnorderedButtonAccessibility = toolbarListUnorderedButtonAccessibility
        self.toolbarListOrderedButtonAccessibility = toolbarListOrderedButtonAccessibility
        self.toolbarIndentIncreaseButtonAccessibility = toolbarIndentIncreaseButtonAccessibility
        self.toolbarIndentDecreaseButtonAccessibility = toolbarIndentDecreaseButtonAccessibility
        self.toolbarCursorUpButtonAccessibility = toolbarCursorUpButtonAccessibility
        self.toolbarCursorDownButtonAccessibility = toolbarCursorDownButtonAccessibility
        self.toolbarCursorPreviousButtonAccessibility = toolbarCursorPreviousButtonAccessibility
        self.toolbarCursorNextButtonAccessibility = toolbarCursorNextButtonAccessibility
        self.toolbarBoldButtonAccessibility = toolbarBoldButtonAccessibility
        self.toolbarItalicsButtonAccessibility = toolbarItalicsButtonAccessibility
        self.keyboardCloseTextFormatMenuButtonAccessibility = keyboardCloseTextFormatMenuButtonAccessibility
        self.keyboardBoldButtonAccessibility = keyboardBoldButtonAccessibility
        self.keyboardItalicsButtonAccessibility = keyboardItalicsButtonAccessibility
        self.keyboardUnderlineButtonAccessibility = keyboardUnderlineButtonAccessibility
        self.keyboardStrikethroughButtonAccessibility = keyboardStrikethroughButtonAccessibility
        self.keyboardReferenceButtonAccessibility = keyboardReferenceButtonAccessibility
        self.keyboardLinkButtonAccessibility = keyboardLinkButtonAccessibility
        self.keyboardListUnorderedButtonAccessibility = keyboardListUnorderedButtonAccessibility
        self.keyboardListOrderedButtonAccessibility = keyboardListOrderedButtonAccessibility
        self.keyboardIndentIncreaseButtonAccessibility = keyboardIndentIncreaseButtonAccessibility
        self.keyboardIndentDecreaseButtonAccessibility = keyboardIndentDecreaseButtonAccessibility
        self.keyboardSuperscriptButtonAccessibility = keyboardSuperscriptButtonAccessibility
        self.keyboardSubscriptButtonAccessibility = keyboardSubscriptButtonAccessibility
        self.keyboardTemplateButtonAccessibility = keyboardTemplateButtonAccessibility
        self.keyboardCommentButtonAccessibility = keyboardCommentButtonAccessibility
        self.wikitextEditorAccessibility = wikitextEditorAccessibility
        self.wikitextEditorLoadingAccessibility = wikitextEditorLoadingAccessibility
        self.findTextFieldAccessibility = findTextFieldAccessibility
        self.findClearButtonAccessibility = findClearButtonAccessibility
        self.findCurrentMatchInfoFormatAccessibility = findCurrentMatchInfoFormatAccessibility
        self.findCurrentMatchInfoZeroResultsAccessibility = findCurrentMatchInfoZeroResultsAccessibility
        self.findCloseButtonAccessibility = findCloseButtonAccessibility
        self.findNextButtonAccessibility = findNextButtonAccessibility
        self.findPreviousButtonAccessibility = findPreviousButtonAccessibility
        self.replaceTextFieldAccessibility = replaceTextFieldAccessibility
        self.replaceClearButtonAccessibility = replaceClearButtonAccessibility
        self.replaceButtonAccessibilityFormat = replaceButtonAccessibilityFormat
        self.replaceTypeButtonAccessibilityFormat = replaceTypeButtonAccessibilityFormat
        self.replaceTypeSingleAccessibility = replaceTypeSingleAccessibility
        self.replaceTypeAllAccessibility = replaceTypeAllAccessibility
    }
}

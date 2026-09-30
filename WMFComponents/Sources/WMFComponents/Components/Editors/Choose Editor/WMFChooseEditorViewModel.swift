import Foundation
import SwiftUI
import WMFData
import WMFNativeLocalizations

@MainActor
public final class WMFChooseEditorViewModel: ObservableObject {

    let title = WMFLocalizedString("choose-editor-title", value: "Choose how to edit", comment: "Title of sheet allowing the user to choose between visual and source editing")
    let dontShowAgainTitle = WMFLocalizedString("choose-editor-dont-show-again", value: "Don't show this again. This default can be changed later in Settings.", comment: "Title of checkbox in the choose editor sheet that suppresses the sheet for future edits")
    let dontShowAgainAccessibilityHint = WMFLocalizedString(
        "choose-editor-dont-show-hint",
        value: "Double tap to remember this choice and skip this screen for future edits.",
        comment: "VoiceOver hint for the don't show again checkbox in the choose editor sheet"
    )
    let continueTitle = CommonStrings.continueButton

    @Published var selectedMode: WMFEditMode
    @Published var dontShowAgain: Bool = false

    let didTapContinue: @MainActor @Sendable (WMFEditMode, _ dontShowAgain: Bool) -> Void
    let didTapClose: @MainActor @Sendable () -> Void

    public init(
        initialMode: WMFEditMode = .visual,
        didTapContinue: @escaping @MainActor @Sendable (WMFEditMode, Bool) -> Void,
        didTapClose: @escaping @MainActor @Sendable () -> Void
    ) {
        self.selectedMode = initialMode
        self.didTapContinue = didTapContinue
        self.didTapClose = didTapClose
    }

    func tappedContinue() {
        didTapContinue(selectedMode, dontShowAgain)
    }

    func tappedClose() {
        didTapClose()
    }
}

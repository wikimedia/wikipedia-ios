import Foundation
import SwiftUI
import WMFNativeLocalizations

@MainActor
public final class WMFChooseEditorViewModel: ObservableObject {

    public enum EditMode {
        case visual
        case source
    }

    let title = WMFLocalizedString("choose-editor-title", value: "Choose how to edit", comment: "Title of sheet allowing the user to choose between visual and source editing")
    let visualEditingTitle = WMFLocalizedString("choose-editor-visual-title", value: "Visual editing", comment: "Title of the visual editing option in the choose editor sheet")
    let visualEditingSubtitle = WMFLocalizedString("choose-editor-visual-subtitle", value: "Make changes directly to the page you see. Opens in your browser.", comment: "Subtitle of the visual editing option in the choose editor sheet")
    let sourceEditingTitle = WMFLocalizedString("choose-editor-source-title", value: "Source editing", comment: "Title of the source editing option in the choose editor sheet")
    let sourceEditingSubtitle = WMFLocalizedString("choose-editor-source-subtitle", value: "Make changes using markup. Stays in the app.", comment: "Subtitle of the source editing option in the choose editor sheet")
    let dontShowAgainTitle = WMFLocalizedString("choose-editor-dont-show-again", value: "Don't show this again. This default can be changed later in Settings.", comment: "Title of checkbox in the choose editor sheet that suppresses the sheet for future edits")
    let continueTitle = CommonStrings.continueButton

    @Published var selectedMode: EditMode
    @Published var dontShowAgain: Bool = false

    let didTapContinue: @MainActor (EditMode, _ dontShowAgain: Bool) -> Void
    let didTapClose: @MainActor () -> Void

    public init(initialMode: EditMode = .visual, didTapContinue: @escaping @MainActor (EditMode, Bool) -> Void, didTapClose: @escaping @MainActor () -> Void) {
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

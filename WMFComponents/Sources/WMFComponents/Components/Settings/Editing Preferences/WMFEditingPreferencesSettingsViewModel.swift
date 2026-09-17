import SwiftUI
import WMFData
import WMFNativeLocalizations

@MainActor
public final class WMFEditingPreferencesSettingsViewModel: ObservableObject {

    let title = WMFEditingPreferencesCopy.title

    @Published private(set) var selectedMode: WMFEditMode

    private let dataController: WMFSettingsDataController
    private let didSelectMode: (@MainActor @Sendable (WMFEditMode) -> Void)?

    public init(dataController: WMFSettingsDataController = WMFSettingsDataController.shared, didSelectMode: (@MainActor @Sendable (WMFEditMode) -> Void)? = nil) {
        self.dataController = dataController
        self.didSelectMode = didSelectMode
        self.selectedMode = dataController.defaultEditMode()
    }

    /// Persists the chosen mode. Deliberately does not touch `skipChooseEditorSheet` — only the
    /// sheet's "Don't show this again" checkbox suppresses the sheet.
    func select(_ mode: WMFEditMode) {
        guard mode != selectedMode else { return }
        selectedMode = mode
        dataController.setDefaultEditMode(mode)
        didSelectMode?(mode)
    }
}

enum WMFEditingPreferencesCopy {
    static let title = WMFLocalizedString("settings-editing-preferences-title", value: "Editing preference", comment: "Title of the editing preferences settings screen, where users pick between visual and source editing.")

    /// Short form used as the value on the Settings row, where the full title does not fit.
    static let visualShortTitle = WMFLocalizedString("settings-editing-preferences-visual-short", value: "Visual", comment: "Short name of the visual editing mode, shown as the current value of the editing preferences row in Settings")
    static let sourceShortTitle = WMFLocalizedString("settings-editing-preferences-source-short", value: "Source", comment: "Short name of the source editing mode, shown as the current value of the editing preferences row in Settings")
}

extension WMFEditMode {

    var localizedShortTitle: String {
        switch self {
        case .visual: return WMFEditingPreferencesCopy.visualShortTitle
        case .source: return WMFEditingPreferencesCopy.sourceShortTitle
        }
    }
}

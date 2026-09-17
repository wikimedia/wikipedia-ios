import SwiftUI

public struct WMFEditingPreferencesSettingsView: View {

    @ObservedObject var viewModel: WMFEditingPreferencesSettingsViewModel
    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    var theme: WMFTheme { appEnvironment.theme }

    public init(viewModel: WMFEditingPreferencesSettingsViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollView {
            // Same card as the choose editor sheet, minus the external link glyph, which the sheet
            // uses to warn that continuing leaves the app.
            WMFEditModeOptionsCard(selectedMode: viewModel.selectedMode, showsExternalLinkIcon: false) { mode in
                viewModel.select(mode)
            }
            .padding(16)
        }
        .multilineTextAlignment(.leading)
        .background(Color(uiColor: theme.midBackground))
        .environment(\.colorScheme, theme.preferredColorScheme)
    }
}

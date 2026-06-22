import SwiftUI

public struct WMFHomeFeedInterestsSettingsView: View {

    @ObservedObject var viewModel: WMFHomeFeedInterestsSettingsViewModel
    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    var theme: WMFTheme { appEnvironment.theme }

    public init(viewModel: WMFHomeFeedInterestsSettingsViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack {
            Spacer()
            Text(viewModel.emptyMessage)
                .font(Font(WMFFont.for(.headline)))
                .foregroundStyle(Color(uiColor: theme.secondaryText))
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: theme.paperBackground))
        .environment(\.colorScheme, theme.preferredColorScheme)
    }
}

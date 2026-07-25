import SwiftUI

public struct WMFHomeFeedCommunitySettingsView: View {

    @ObservedObject var viewModel: WMFHomeFeedCommunitySettingsViewModel
    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    var theme: WMFTheme { appEnvironment.theme }

    public init(viewModel: WMFHomeFeedCommunitySettingsViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack {
            Color(uiColor: theme.midBackground)
                .ignoresSafeArea()
            List {
                ForEach(viewModel.sections) { section in
                    Section(
                        header: section.header.map { headerText in
                            Text(headerText)
                                .font(Font(WMFFont.for(.footnote)))
                                .foregroundStyle(Color(uiColor: theme.secondaryText))
                        }
                    ) {
                        ForEach(section.items) { item in
                            SettingsRow(item: item)
                                .contentShape(Rectangle())
                                .listRowBackground(Color(uiColor: theme.chromeBackground))
                                .listRowSeparator(.hidden)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
        .environment(\.colorScheme, theme.preferredColorScheme)
    }
}

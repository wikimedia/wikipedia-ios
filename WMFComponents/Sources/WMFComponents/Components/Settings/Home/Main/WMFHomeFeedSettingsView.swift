import SwiftUI

public struct WMFHomeFeedSettingsView: View {

    @ObservedObject var viewModel: WMFHomeFeedSettingsViewModel
    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    var theme: WMFTheme { appEnvironment.theme }

    public init(viewModel: WMFHomeFeedSettingsViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack {
            Color(uiColor: theme.midBackground)
                .ignoresSafeArea()
            List {
                ForEach(viewModel.sections) { section in
                    Section(header: section.header.map(Text.init)) {
                        ForEach(section.items) { item in
                            Button {
                                item.action?()
                            } label: {
                                SettingsRow(item: item)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
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

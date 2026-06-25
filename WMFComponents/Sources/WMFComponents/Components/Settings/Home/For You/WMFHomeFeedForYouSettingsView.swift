import SwiftUI

public struct WMFHomeFeedForYouSettingsView: View {

    @ObservedObject var viewModel: WMFHomeFeedForYouSettingsViewModel
    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    var theme: WMFTheme { appEnvironment.theme }

    public init(viewModel: WMFHomeFeedForYouSettingsViewModel) {
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
                            row(for: item)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
        .environment(\.colorScheme, theme.preferredColorScheme)
    }

    @ViewBuilder
    private func row(for item: SettingsItem) -> some View {
        if let action = item.action {
            Button {
                action()
            } label: {
                SettingsRow(item: item)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .listRowBackground(Color(uiColor: theme.chromeBackground))
            .listRowSeparator(.hidden)
        } else {
            SettingsRow(item: item)
                .contentShape(Rectangle())
                .listRowBackground(Color(uiColor: theme.chromeBackground))
                .listRowSeparator(.hidden)
        }
    }
}

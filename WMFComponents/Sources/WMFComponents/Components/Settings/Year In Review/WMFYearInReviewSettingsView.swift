import SwiftUI
import WMFData

// MARK: - Year in Review Settings View

public struct WMFYearInReviewSettingsView: View {
    @ObservedObject private var appEnvironment = WMFAppEnvironment.current
    private var theme: WMFTheme { appEnvironment.theme }

    @StateObject private var viewModel: WMFYearInReviewSettingsViewModel

    public init(viewModel: WMFYearInReviewSettingsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
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
                        },

                        footer: section.footer.map { footerText in
                            Text(footerText)
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
        .navigationTitle(viewModel.localizedStrings.title)
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.colorScheme, theme.preferredColorScheme)
    }

    // MARK: - Rows

    @ViewBuilder
    private func row(for item: SettingsItem) -> some View {
        switch item.accessory {
        case .toggle:
            SettingsRow(item: item)
                .contentShape(Rectangle())
                .listRowBackground(Color(uiColor: theme.chromeBackground))
                .listRowSeparator(.hidden)

        case .none, .icon, .chevron:
            Text("") // can't break
        }
    }
}

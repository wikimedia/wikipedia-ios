import SwiftUI

private struct SettingsRow: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    var theme: WMFTheme { appEnvironment.theme }

    let item: SettingsItem

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            if let image = item.image {
                Image(uiImage: image)
                    .frame(width: 16, height: 16)
                    .foregroundStyle(Color(uiColor: theme.chromeBackground))
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(uiColor:  theme.isLightTheme ? item.color : theme.newBorder))
                            .frame(width: 32, height: 32)
                    )
                    .padding(.leading, 8)
                    .padding(.trailing, 16)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(Font(WMFFont.for(.body)))
                if let subtitle = item.subtitle {
                    Text(subtitle)
                        .font(Font(WMFFont.for(.subheadline)))
                        .foregroundColor(Color(uiColor: theme.secondaryText))
                }
            }
            Spacer()
            accessoryView()
        }

    }

    @ViewBuilder
    private func accessoryView() -> some View {
        switch item.accessory {
        case .none:
            EmptyView()
        case .toggle(let binding):
            Toggle("", isOn: binding)
                .labelsHidden()
        case .icon(let image):
            if let image {
                Image(uiImage: image)
                    .foregroundStyle(Color(uiColor: theme.secondaryText))
            }
        case .chevron(label: let label):
            HStack(spacing: 4) {
                if let label = label {
                    Text(label)
                        .font(Font(WMFFont.for(.body)))
                        .foregroundColor(Color(uiColor: theme.secondaryText))
                }
                if let image = WMFSFSymbolIcon.for(symbol: .chevronForward) {
                    Image(uiImage: image)
                        .foregroundStyle(Color(uiColor: theme.secondaryText))
                }
            }
        }
    }
}

struct WMFSettingsView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    var theme: WMFTheme { appEnvironment.theme }

    @ObservedObject var viewModel: WMFSettingsViewModel

    var body: some View {
        ZStack {
            Color(uiColor: theme.midBackground)
                .ignoresSafeArea()
            List {
                ForEach(viewModel.sections) { section in
                    Section(
                        header: section.header.map(Text.init),
                        footer: section.footer.map { footerText in
                            Text(footerText)
                                .font(Font(WMFFont.for(.footnote)))
                                .foregroundColor(Color(uiColor: theme.secondaryText))
                        }
                    ) {
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

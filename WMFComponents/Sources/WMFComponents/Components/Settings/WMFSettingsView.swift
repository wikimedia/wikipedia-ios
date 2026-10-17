import SwiftUI

struct SettingsRow: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    var theme: WMFTheme { appEnvironment.theme }

    let item: SettingsItem

    var body: some View {
        HStack(alignment: .center, spacing: WMFSpacing.medium) {
            if let image = item.image, let color = item.color {
                Image(uiImage: image)
                    .frame(width: 16, height: 16)
                    .foregroundStyle(Color(uiColor: theme == .light ? theme.chromeBackground : theme.icon))
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(uiColor: theme == .light ? color : theme.iconBackground))
                            .frame(width: 32, height: 32)
                    )
                    .padding(.leading, WMFSpacing.small)
                    .padding(.trailing, WMFSpacing.large)
            }
            VStack(alignment: .leading, spacing: WMFSpacing.xxSmall) {
                if item.showsBetaBadge {
                    WMFBetaBadge()
                        .padding(.bottom, WMFSpacing.xxSmall)
                }
                Text(item.title)
                    .font(Font(WMFFont.for(.body)))
                if let subtitle = item.subtitle {
                    Text(subtitle)
                        .font(Font(WMFFont.for(.footnote)))
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
                .toggleStyle(SwitchToggleStyle(tint: Color(uiColor: theme.accent)))
        case .icon(let image):
            if let image {
                Image(uiImage: image)
                    .foregroundStyle(Color(uiColor: theme.secondaryText))
            }
        case .chevron(label: let label):
            HStack(spacing: WMFSpacing.xSmall) {
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

public struct WMFSettingsView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    var theme: WMFTheme { appEnvironment.theme }

    @ObservedObject var viewModel: WMFSettingsViewModel

    public init(viewModel: WMFSettingsViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
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
            .ignoresSafeArea(.keyboard)
        }
        .environment(\.colorScheme, theme.preferredColorScheme)
    }

}

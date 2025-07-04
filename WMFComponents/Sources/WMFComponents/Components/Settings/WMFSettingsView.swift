import SwiftUI

private struct SettingsRowContent: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    var theme: WMFTheme {
        return appEnvironment.theme
    }
    let item: SettingsItem

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            if let image = item.image {
                Image(uiImage: image)
                    .frame(width: 16, height: 16)
                    .foregroundStyle(Color(uiColor: theme.chromeBackground))
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(uiColor: item.color))
                            .frame(width: 32, height: 32)
                            .padding(0)
                    )
                    .padding(.trailing, 16)
                    .padding(.leading, 8)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.body)
                if let subtitle = item.subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
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
        case .icon(let name):
            Image(systemName: name)
        case .label(let label):
            HStack(spacing: 4) {
                if let label = label {
                    Text(label)
                }
            }
        }
    }
}

struct WMFSettingsView: View {
    @ObservedObject var viewModel: WMFSettingsViewModel

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.sections) { section in
                    Section(
                        header: section.header.map(Text.init),
                        footer: section.footer.map {
                            Text($0)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    ) {
                        ForEach(section.items) { item in
                            if let children = item.subSections {
                                NavigationLink(destination: WMFSettingsView(
                                    viewModel: WMFSettingsViewModel(sections: children)
                                )) {
                                    SettingsRowContent(item: item)
                                }
                            } else {
                                SettingsRowContent(item: item)
                                    .contentShape(Rectangle())
                                    .onTapGesture { item.action?() }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }
}

import SwiftUI

struct SettingsRow: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    var theme: WMFTheme {
        return appEnvironment.theme
    }
    let item: SettingsItem

    @ViewBuilder
    private func accessoryView() -> some View {
        switch item.accessory {
        case .none:       EmptyView()
        case .label(let text): Text(text)
        case .toggle(let binding): Toggle("", isOn: binding).labelsHidden()
        case .icon(let name): Image(systemName: name)
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: item.iconName)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.body)
                if let sub = item.subtitle {
                    Text(sub)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            accessoryView()

            if item.showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                    .padding(.leading, 4)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture { item.action?() }
    }
}

struct SettingsView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    var theme: WMFTheme {
        return appEnvironment.theme
    }
    @StateObject private var viewModel:WMFSettingsViewModel

    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.sections) { section in
                    Section(
                        header: section.header.map(Text.init),
                        footer: section.footer.map {
                            Text($0).font(.footnote).foregroundColor(.secondary)
                        }
                    ) {
                        ForEach(section.items) { item in
                            // if it has subSections, you’d wrap in a NavigationLink;
                            // here’s the basic row:
                            SettingsRow(item: item)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

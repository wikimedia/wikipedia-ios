import SwiftUI

public struct WMFNewArticleTabSettingsView: View {
    @ObservedObject var viewModel: WMFNewArticleTabSettingsViewModel
    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    var theme: WMFTheme {
        return appEnvironment.theme
    }

    public init(viewModel: WMFNewArticleTabSettingsViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        List {
            Section(header: Text(viewModel.header)) {
                ForEach(viewModel.options.indices, id: \.self) { index in
                    HStack {
                        Text(viewModel.options[index])
                            .foregroundStyle(Color(theme.text))
                            .font(Font(WMFFont.for(.body)))
                        Spacer()
                        if viewModel.selectedIndex == index {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color(theme.link))
                        }
                    }
                    .background((Color(theme.paperBackground)))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.selectedIndex = index
                    }
                }
            }
        }
        .navigationTitle(viewModel.title)
        .background(Color(theme.midBackground).ignoresSafeArea())
        .listStyle(.insetGrouped)
    }
}

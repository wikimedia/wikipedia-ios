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
            Section(header: Text(viewModel.header)
                .foregroundStyle(Color(theme.secondaryText))
            ) {
                ForEach(viewModel.options.indices, id: \.self) { index in
                    HStack {
                        Text(viewModel.options[index])
                            .foregroundStyle(Color(theme.text))
                            .font(Font(WMFFont.for(.body)))
                        Spacer()
                        if viewModel.shouldShowCheckmark(for: index),
                           let uiImage = WMFSFSymbolIcon.for(symbol: .checkmark) {
                            Image(uiImage: uiImage)
                                .foregroundStyle(Color(theme.link))
                        }
                    }
                    .contentShape(Rectangle())
                    .listRowBackground(Color(theme.paperBackground))
                    .onTapGesture {
                        viewModel.selectedIndex = index
                    }
                }
            }
        }
        .listBackgroundColor(Color(theme.midBackground))
        .listStyle(.insetGrouped)
    }
}

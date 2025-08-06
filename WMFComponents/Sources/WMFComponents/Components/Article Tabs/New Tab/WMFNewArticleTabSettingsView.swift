import SwiftUI

public struct WMFNewArticleTabSettingsView: View {
    @ObservedObject var viewModel: WMFNewArticleTabSettingsViewModel

    public init(viewModel: WMFNewArticleTabSettingsViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        List {
            Section(header: Text(viewModel.header)) {
                ForEach(viewModel.options.indices, id: \.self) { index in
                    HStack {
                        Text(viewModel.options[index])
                        Spacer()
                        if viewModel.selectedIndex == index {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.selectedIndex = index
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(viewModel.title)
    }
}

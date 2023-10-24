import SwiftUI

struct WKFormSectionSelectView: View {
    @ObservedObject var appEnvironment = WKAppEnvironment.current

    var theme: WKTheme {
        return appEnvironment.theme
    }

    let viewModel: WKFormSectionSelectViewModel

    var body: some View {
        Section {
            ForEach(viewModel.items) { item in
                switch viewModel.selectType {
                case .multi:
                    WKFormSelectMultiRowView(viewModel: item)
                case .single:
                    WKFormSelectSingleRowView(viewModel: item)
                }
            }
        } header: {
            if let header = viewModel.header {
                Text(header)
            }
        } footer: {
            if let footer = viewModel.footer {
                Text(footer)
            }
        }
    }
}

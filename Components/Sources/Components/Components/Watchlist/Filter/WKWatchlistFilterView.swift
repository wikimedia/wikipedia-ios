import SwiftUI

struct WKWatchlistFilterView: View {
    
    @ObservedObject var appEnvironment = WKAppEnvironment.current

    var theme: WKTheme {
        return appEnvironment.theme
    }

    let viewModel: WKWatchlistFilterViewModel
    let doneAction: () -> Void

    var body: some View {
        NavigationView {
            WKFormView(viewModel: viewModel.formViewModel)
                .navigationTitle(viewModel.localizedStrings.title)
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(
                    trailing:
                        Button(action: {
                            doneAction()
                        }) {
                            Text(viewModel.localizedStrings.doneTitle)
                                .foregroundColor(Color(theme.text))
                            }
                )
        }
        .navigationViewStyle(.stack)
        .accessibilityAction(.escape) {
            doneAction()
        }
    }
}

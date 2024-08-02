import SwiftUI

struct WMFWatchlistFilterView: View {
    
    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    var theme: WMFTheme {
        return appEnvironment.theme
    }

	@ObservedObject var viewModel: WMFWatchlistFilterViewModel
    let doneAction: () -> Void

    var body: some View {
        NavigationView {
            WMFFormView(viewModel: viewModel.formViewModel)
                .navigationTitle(viewModel.localizedStrings.title)
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(
                    trailing:
                        Button(action: {
                            doneAction()
                        }) {
                            Text(viewModel.localizedStrings.doneTitle)
                                .font(Font(WMFFont.for(.headline)))
                                .foregroundColor(Color(theme.link))
                            }
                )
        }
        .navigationViewStyle(.stack)
        .accessibilityAction(.escape) {
            doneAction()
        }
    }
}

import SwiftUI

struct WMFWatchlistFilterView: View {
    
    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    var theme: WMFTheme {
        return appEnvironment.theme
    }

	@ObservedObject var viewModel: WMFWatchlistFilterViewModel
    let doneAction: () -> Void

    var body: some View {
            WMFFormView(viewModel: viewModel.formViewModel)
                .navigationTitle(viewModel.localizedStrings.title)
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(
                    trailing:
                        WMFLargeCloseButton(imageType: .plainX, action: {
                            doneAction()
                        })
                )
                .accessibilityAction(.escape) {
                    doneAction()
                }
            }
    }

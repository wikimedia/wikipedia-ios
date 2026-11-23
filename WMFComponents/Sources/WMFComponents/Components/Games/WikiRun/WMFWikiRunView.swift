import SwiftUI

public struct WMFWikiRunView: View {

    @ObservedObject private var viewModel: WMFWikiRunViewModel
    @ObservedObject private var appEnvironment = WMFAppEnvironment.current

    public init(viewModel: WMFWikiRunViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack {
            WMFWikiRunWebView(viewModel: viewModel)
                .ignoresSafeArea(edges: .bottom)

            if viewModel.loadState == .failed {
                errorView
            }
        }
    }

    private var errorView: some View {
        VStack(spacing: 16) {
            Text(viewModel.localizedStrings.errorTitle)
                .font(Font(WMFFont.for(.semiboldHeadline)))
                .foregroundColor(Color(appEnvironment.theme.text))
                .multilineTextAlignment(.center)

            Text(viewModel.localizedStrings.errorMessage)
                .font(Font(WMFFont.for(.subheadline)))
                .foregroundColor(Color(appEnvironment.theme.secondaryText))
                .multilineTextAlignment(.center)

            WMFLargeButton(style: .primary, title: viewModel.localizedStrings.retryButton) {
                viewModel.retryLoading()
            }
            .padding(.top, 8)

            WMFLargeButton(style: .quiet, title: viewModel.localizedStrings.closeButton) {
                viewModel.close()
            }
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(appEnvironment.theme.midBackground))
        .ignoresSafeArea()
    }
}

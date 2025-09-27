import SwiftUI

struct WMFYearInReviewDonateButton: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: WMFYearInReviewViewModel

    @State private var buttonRect: CGRect = .zero

    var theme: WMFTheme {
        return appEnvironment.theme
    }

    var body: some View {
        Button(action: {
            viewModel.handleDonate()
        }) {

            ZStack {

                HStack(alignment: .center, spacing: 6) {
                    if let uiImage = WMFSFSymbolIcon.for(symbol: .heartFilled, font: .semiboldHeadline) {
                        Image(uiImage: uiImage)
                            .foregroundStyle(Color(uiColor: theme.destructive))
                    }
                    Text(viewModel.localizedStrings.donateButtonTitle)
                        .foregroundStyle(Color(uiColor: theme.destructive))
                }
                .font(Font(WMFFont.for(.semiboldHeadline)))
                .opacity(viewModel.isLoadingDonate ? 0 : 1)

                if viewModel.isLoadingDonate {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color(uiColor: theme.destructive)))
                        .scaleEffect(1.2)
                        .background(
                            GeometryReader { geometry in
                                Color.clear
                                    .onAppear {
                                        let frame = geometry.frame(in: .global)
                                        viewModel.donateButtonRect = frame
                                    }
                            }
                        )
                }
            }
        }
        .disabled(viewModel.isLoadingDonate)
        .animation(.easeInOut, value: viewModel.isLoadingDonate)
    }

}


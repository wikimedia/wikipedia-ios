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
            viewModel.handleDonate(sourceRect: buttonRect)
            viewModel.logYearInReviewDidTapDonate()
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
                .opacity(viewModel.isLoading ? 0 : 1)

                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color(uiColor: theme.destructive)))
                        .scaleEffect(1.2)
                }
            }
        }
        .disabled(viewModel.isLoading)
        .background(
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        let frame = geometry.frame(in: .global)
                        buttonRect = frame
                    }
            }
        )
        .animation(.easeInOut, value: viewModel.isLoading)
    }

}


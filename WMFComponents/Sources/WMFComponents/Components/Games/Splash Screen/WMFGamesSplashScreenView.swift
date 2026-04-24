import SwiftUI

public struct WMFGamesSplashScreenView: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: WMFGamesSplashScreenViewModel

    public init(viewModel: WMFGamesSplashScreenViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body

    public var body: some View {
        ZStack {
            Color(uiColor: viewModel.backgroundColor)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 16) {
                    Image(uiImage: viewModel.icon ?? UIImage())
                        .font(.system(size: 52, weight: .regular))
                        .foregroundColor(.white)

                    Text(viewModel.localizedStrings.title)
                        .font(Font(WMFFont.for(.georgiaTitle1)))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text(viewModel.localizedStrings.subtitle)
                        .font(Font(WMFFont.for(.callout)))
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Spacer()

                WMFLargeButton(
                    style: .neutral,
                    title: viewModel.localizedStrings.playButtonTitle,
                    action: { viewModel.didTapPlay?() }
                )
                .padding(.horizontal, 32)

                Spacer()

                Button {
                    viewModel.didTapAbout?()
                } label: {
                    Text(viewModel.localizedStrings.aboutButtonTitle)
                        .font(Font(WMFFont.for(.semiboldSubheadline)))
                        .foregroundColor(.white)
                }
                .padding(.bottom, 24)
            }
        }
    }
}


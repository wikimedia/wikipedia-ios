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
            Color(uiColor: WMFColor.blue600)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 16) {
                    Image(uiImage: viewModel.icon ?? UIImage())
                        .resizable()
                        .scaledToFit()
                        .frame(width: 44, height: 44)
                        .foregroundColor(.white)

                    Text(viewModel.title)
                        .font(Font(WMFFont.for(.georgiaTitle1)))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text(viewModel.subtitle)
                        .font(Font(WMFFont.for(.callout)))
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(.bottom, 48)

                WMFLargeButton(
                    style: .neutral,
                    title: viewModel.playButtonTitle,
                    forceBackgroundColor: WMFColor.white,
                    forceForegroundColor: WMFColor.blue600,
                    action: { viewModel.didTapPlay?() }
                )
                .padding(.horizontal, 32)

                Spacer()

                WMFLargeButton(
                    style: .quiet,
                    title: viewModel.aboutButtonTitle,
                    forceForegroundColor: WMFColor.white,
                    action: { viewModel.didTapAbout?() }
                )
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
            }
        }
    }
}


import SwiftUI

public struct WMFGamesSplashScreenView: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject public var viewModel: WMFGamesSplashScreenViewModel

    public init(viewModel: WMFGamesSplashScreenViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body

    public var body: some View {
        ZStack {
            Color(uiColor: WMFColor.blue600)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: 48)

                    VStack {
                        Image(uiImage: viewModel.icon ?? UIImage())
                            .resizable()
                            .scaledToFit()
                            .frame(width: 44, height: 44)
                            .foregroundColor(Color(uiColor: WMFColor.white))
                            .padding(.bottom, 24)

                        Text(viewModel.title)
                            .font(Font(WMFFont.for(.georgiaTitle1)))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 8)

                        Text(viewModel.subtitle)
                            .font(Font(WMFFont.for(.body)))
                            .foregroundColor(Color(uiColor: WMFColor.white))
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

                    Spacer(minLength: 24)

                    WMFLargeButton(
                        style: .quiet,
                        title: viewModel.aboutButtonTitle,
                        forceForegroundColor: WMFColor.white,
                        action: { viewModel.didTapAbout?() }
                    )
                    .padding(.horizontal, 32)
                    .padding(.bottom, 24)
                }
                .frame(minHeight: UIScreen.main.bounds.height - 100)
            }
        }
    }
}


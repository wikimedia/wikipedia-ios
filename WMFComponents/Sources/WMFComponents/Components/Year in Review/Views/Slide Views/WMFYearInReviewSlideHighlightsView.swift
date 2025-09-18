import SwiftUI

public struct WMFYearInReviewSlideHighlightsView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    var theme: WMFTheme { appEnvironment.theme }
    var viewModel: WMFYearInReviewSlideHighlightsViewModel

    public var body: some View {
        ZStack {
            GradientBackgroundView()

            GeometryReader { proxy in
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: 0) {
                        Spacer(minLength: 0)

                        VStack(spacing: 24) {
                            Text(viewModel.localizedStrings.title)
                                .font(Font(WMFFont.for(.boldTitle1)))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)

                            Text(viewModel.localizedStrings.subtitle)
                                .font(Font(WMFFont.for(.headline)))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)

                            WMFYearInReviewInfoboxView(
                                viewModel: viewModel.infoBoxViewModel,
                                isSharing: false
                            )
                            .overlay(
                                Rectangle().stroke(Color(WMFColor.gray300), lineWidth: 1)
                            )
                            .frame(maxWidth: 350)
                            .frame(maxWidth: .infinity)
                            
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 24)

                        Spacer(minLength: 0)
                    }
                    .frame(minHeight: proxy.size.height)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            WMFLargeButton(configuration: .primary,
                           title: viewModel.localizedStrings.buttonTitle) {
                withAnimation(.easeInOut(duration: 0.75)) {
                    viewModel.tappedShare()
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 16)
            .padding(.top, 32)
        }
    }
}

struct GradientBackgroundView: View {
    var body: some View {
        ZStack {
            // Base vertical gradient
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: .black, location: 0.00),
                    .init(color: Color(red: 9/255,  green: 45/255,  blue: 96/255),location: 0.35),
                    .init(color: Color(red: 17/255, green: 113/255,  blue: 200/255),location: 0.50),
                    .init(color: Color(red: 61/255, green: 178/255, blue: 255/255),location: 0.65),
                    .init(color: Color(red: 211/255, green: 241/255, blue: 243/255),location: 0.80)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )

            // Top black vignette (makes the top shadow darker)
            LinearGradient(
                colors: [.black.opacity(0.65), .clear],
                startPoint: .top,
                endPoint: .center
            )
            .blendMode(.multiply)

            // Bottom glow
            LinearGradient(
                colors: [.white.opacity(0.18), .clear],
                startPoint: .bottom,
                endPoint: .center
            )
            .blendMode(.screen)
        }
        .compositingGroup()
        .ignoresSafeArea()
    }
}

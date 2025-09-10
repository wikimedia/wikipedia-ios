import SwiftUI

public struct WMFYearInReviewSlideHighlightsView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    var theme: WMFTheme { appEnvironment.theme }
    var viewModel: WMFYearInReviewSlideHighlightsViewModel

    public var body: some View {
        ZStack {
            GradientBackgroundView()
                .ignoresSafeArea(.container, edges: [.top])

            GeometryReader { proxy in
                ScrollView(.vertical, showsIndicators: true) {

                    VStack {
                        Spacer(minLength: 0)
                        VStack(spacing: 24) {
                            Text("Titleeeeee loooooooooooooooooooooooong long")
                                .font(Font(WMFFont.for(.boldTitle1)))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)

                            Text("subtitle loooooooooooooooooooooooong")
                                .font(Font(WMFFont.for(.headline)))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)

                            WMFYearInReviewInfoTableView(viewModel: viewModel.getTableViewModel())
                                .overlay(
                                    Rectangle()
                                        .stroke(Color(WMFColor.gray300), lineWidth: 1)
                                )

                            WMFLargeButton(configuration: .primary, title: "title") {
                                withAnimation(.easeInOut(duration: 0.75)) {
                                    viewModel.tappedShare()
                                }
                            }
                            .padding(.top, 8)
                        }
                        .padding(.horizontal, 32)
                        .padding(.vertical, 24)

                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: proxy.size.height)
                }
            }
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

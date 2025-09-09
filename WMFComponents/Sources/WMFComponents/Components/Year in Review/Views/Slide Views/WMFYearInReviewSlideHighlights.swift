import SwiftUI

public struct WMFYearInReviewSlideHighlightsView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    var theme: WMFTheme { appEnvironment.theme }
    var viewModel: WMFYearInReviewSlideHighlightsViewModel

    public var body: some View {
        ZStack {
            GradientBackgroundView()
                .ignoresSafeArea(.container, edges: [.top]) // don't ignore bottom

            ScrollView(.vertical, showsIndicators: true) {
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


                    WMFLargeButton(configuration: .primary, title: "title") {
                        withAnimation(.easeInOut(duration: 0.75)) { }
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 32)
                .padding(.top, 24)
                .padding(.bottom, 32)
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

import SwiftUI
import WMFData

struct WMFActivityTabYearInReviewCardView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: WMFActivityTabYearInReviewViewModel

    var theme: WMFTheme {
        return appEnvironment.theme
    }

    // The gradient is dark in every theme, so the foreground is fixed rather than
    // following theme.text.
    private var foreground: Color {
        Color(uiColor: WMFColor.white)
    }

    // Stops come from Figma. The center sits below the card, so only the top of the glow shows.
    // Figma's export leaves endRadiusFraction at 0.5, which puts every light stop below the card.
    // At 1, the 0.15 stop falls on the bottom edge, as in the design.
    private var backgroundGradient: EllipticalGradient {
        EllipticalGradient(
            stops: [
                Gradient.Stop(color: Color(red: 0.95, green: 0.95, blue: 0.95), location: 0.15),
                Gradient.Stop(color: Color(red: 0.27, green: 0.83, blue: 0.94), location: 0.25),
                Gradient.Stop(color: Color(red: 0, green: 0.6, blue: 0.85), location: 0.35),
                Gradient.Stop(color: Color(red: 0, green: 0.26, blue: 0.48), location: 0.53),
                Gradient.Stop(color: Color(red: 0.05, green: 0.15, blue: 0.32), location: 0.63),
                Gradient.Stop(color: Color(red: 0.02, green: 0.09, blue: 0.22), location: 0.75)
            ],
            center: UnitPoint(x: 0.5, y: 1.15),
            endRadiusFraction: 1
        )
    }

    private var accessibilityLabel: String {
        [viewModel.title, viewModel.subtitle, viewModel.ctaTitle].joined(separator: ". ")
    }

    var body: some View {
        VStack(spacing: 8) {
            Text(viewModel.title)
                .font(Font(WMFFont.for(.semiboldHeadline)))
                .foregroundColor(foreground)
            Text(viewModel.subtitle)
                .font(Font(WMFFont.for(.callout)))
                .foregroundColor(foreground)
            WMFMediumButton(
                configuration: .init(style: .primary),
                title: viewModel.ctaTitle,
                action: {
                    viewModel.onTap?()
                }
            )
            .padding(.top, 8)
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(backgroundGradient)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        // Tap handling sits above the horizontal padding so the gutter beside the card is not
        // part of the tap target.
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.onTap?()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(.isButton)
        .padding(.horizontal, 16)
    }
}

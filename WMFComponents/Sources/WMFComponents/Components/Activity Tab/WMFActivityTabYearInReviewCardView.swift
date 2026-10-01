import SwiftUI
import WMFData

struct WMFActivityTabYearInReviewCardView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: WMFActivityTabYearInReviewViewModel

    var theme: WMFTheme {
        return appEnvironment.theme
    }

    // The gradient artwork is dark in every theme, so the foreground is fixed rather than
    // following theme.text.
    private var foreground: Color {
        Color(uiColor: WMFColor.white)
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
        .background(
            Image("yir_teaser_gradient", bundle: .module)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .accessibilityHidden(true)
        )
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

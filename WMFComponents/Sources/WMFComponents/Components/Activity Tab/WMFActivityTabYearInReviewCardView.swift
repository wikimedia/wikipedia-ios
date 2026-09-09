import SwiftUI
import WMFData

struct WMFActivityTabYearInReviewCardView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: WMFActivityTabYearInReviewViewModel

    var theme: WMFTheme {
        return appEnvironment.theme
    }

    // The gradient artwork is dark in both light and dark mode, so the foreground
    // is fixed white rather than following theme.text.
    private let foreground = Color.white

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
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.onTap?()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(viewModel.title). \(viewModel.subtitle)")
        .accessibilityAddTraits(.isButton)
    }
}

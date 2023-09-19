import SwiftUI

struct WKOnboardingCell: View {

    // MARK: - Properties

    @ObservedObject var appEnvironment = WKAppEnvironment.current

    var viewModel: WKOnboardingViewModel.WKOnboardingCellViewModel

    // MARK: - Lifecycle

    var body: some View {
        HStack {
            VStack {
                if let icon = viewModel.icon {
                    Image(uiImage: icon)
                        .foregroundColor(Color(appEnvironment.theme.link))
                        .accessibilityHidden(true)
                        .padding([.trailing], 12)
                }
                Spacer()
            }
            VStack() {
                Text(viewModel.title)
                    .multilineTextAlignment(.leading)
                    .font(Font(WKFont.for(.boldBody)))
                    .foregroundColor(Color(appEnvironment.theme.text))
                    .padding([.bottom], 1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let subtitle = viewModel.subtitle {
                    Text(subtitle)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(Color(appEnvironment.theme.secondaryText))
                        .font(Font(WKFont.for(.subheadline)))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

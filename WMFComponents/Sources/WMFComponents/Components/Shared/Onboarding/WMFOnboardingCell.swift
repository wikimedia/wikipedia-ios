import SwiftUI

struct WMFOnboardingCell: View {

    // MARK: - Properties

    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    var viewModel: WMFOnboardingViewModel.WMFOnboardingCellViewModel

    // MARK: - Lifecycle

    var body: some View {
		HStack(alignment: .top) {
            VStack {
                if let icon = viewModel.icon {
                    if viewModel.fillIconBackground {
						Image(uiImage: icon)
						    .foregroundColor(Color(appEnvironment.theme.link))
						    .padding(5)
						    .accessibilityHidden(true)
							.background(Color(appEnvironment.theme.link.withAlphaComponent(0.25)))
						    .clipShape(Circle())
                    } else {
					    Image(uiImage: icon)
						    .foregroundColor(Color(appEnvironment.theme.link))
						    .padding([.trailing], 12)
						    .accessibilityHidden(true)
                    }
                }
                Spacer()
            }
            VStack {
                Text(viewModel.title)
                    .multilineTextAlignment(.leading)
                    .font(Font(WMFFont.for(.boldCallout)))
                    .foregroundColor(Color(appEnvironment.theme.text))
                    .padding([.bottom], 1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let subtitle = viewModel.subtitle {
                    Text(subtitle)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(Color(appEnvironment.theme.secondaryText))
                        .font(Font(WMFFont.for(.subheadline)))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

#Preview {
	WMFOnboardingCell(viewModel: .init(icon: .checkmark, title: "Title 1", subtitle: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."))
		.frame(width: 300, height: 100)
}

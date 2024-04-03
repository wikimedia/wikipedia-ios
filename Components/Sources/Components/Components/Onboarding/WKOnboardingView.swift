import SwiftUI

public struct WKOnboardingView: View {

    // MARK: - Properties

    var viewModel: WKOnboardingViewModel
    var primaryButtonAction: (() -> Void)?
    var secondaryButtonAction: (() -> Void)?

    @ObservedObject var appEnvironment = WKAppEnvironment.current

    @Environment (\.horizontalSizeClass) private var horizontalSizeClass

    var sizeClassPadding: CGFloat {
        horizontalSizeClass == .regular ? 64 : 32
    }

    // MARK: - Lifecycle

	var content: some View {
		Group {
			ScrollView(showsIndicators: true) {
				VStack {
					Text(viewModel.title)
						.font(Font(WKFont.for(.boldTitle1)))
						.foregroundColor(Color(appEnvironment.theme.text))
						.padding(.bottom, 44)
						.padding(.top, 44 + sizeClassPadding)
						.multilineTextAlignment(.center)
					ForEach(1...viewModel.cells.count, id:\.self) { cell in
						VStack {
							WKOnboardingCell(viewModel: viewModel.cells[cell - 1])
								.padding(.bottom, 24)
								.padding(.trailing, 20)
						}
					}
				}
				.padding(.bottom, 125)
			}
			ZStack(alignment: .bottom, content: {
				VStack {
					WKLargeButton(configuration: .primary, title: viewModel.primaryButtonTitle, action: primaryButtonAction)
						.padding([.top], 16)

					if let secondaryTitle = viewModel.secondaryButtonTitle {
						let configuration = WKSmallButton.Configuration(style: .quiet)
						WKSmallButton(configuration: configuration, title: secondaryTitle, action: secondaryButtonAction)
					}
				}
			})
		}
		.padding([.leading, .trailing, .bottom], sizeClassPadding)
	}

    public var body: some View {
		ZStack(alignment: .bottom) {
			Color(appEnvironment.theme.paperBackground).ignoresSafeArea()
			content
		}		
    }

}

#Preview {
	WKOnboardingView(viewModel: .init(title: "Onboarding View", cells: [.init(icon: .add, title: "Title 1", subtitle: "Subtitle 1"), .init(icon: .checkmark, title: "Title 2", subtitle: "Subtitle 2")], primaryButtonTitle: "Primary Button", secondaryButtonTitle: "Secondary Button"))
}

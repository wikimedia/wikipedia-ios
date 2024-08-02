import SwiftUI

public struct WMFOnboardingView: View {

    // MARK: - Properties

    var viewModel: WMFOnboardingViewModel
    var primaryButtonAction: (() -> Void)?
    var secondaryButtonAction: (() -> Void)?

    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var sizeClassPadding: CGFloat {
        horizontalSizeClass == .regular ? 64 : 32
    }
    
    @ScaledMetric var scrollViewBottomInset = 125.0

    // MARK: - Lifecycle

	var content: some View {
        ZStack(alignment: .bottom, content: {
			ScrollView(showsIndicators: true) {
				VStack {
					Text(viewModel.title)
						.font(Font(WMFFont.for(.boldTitle1)))
						.foregroundColor(Color(appEnvironment.theme.text))
                        .padding(.bottom, 44)
                        .padding(.top, 44 + sizeClassPadding)
						.multilineTextAlignment(.center)
					ForEach(1...viewModel.cells.count, id:\.self) { cell in
						VStack {
							WMFOnboardingCell(viewModel: viewModel.cells[cell - 1])
								.padding(.bottom, 24)
								.padding(.trailing, 20)
						}
					}
				}
                .padding(EdgeInsets(top: 0, leading: sizeClassPadding, bottom: scrollViewBottomInset, trailing: sizeClassPadding))
			}
            VStack(spacing: 20) {
                WMFLargeButton(configuration: .primary, title: viewModel.primaryButtonTitle, action: primaryButtonAction)
                    .padding([.top], 16)

                if let secondaryTitle = viewModel.secondaryButtonTitle {
                    let configuration = WMFSmallButton.Configuration(style: .quiet)
                    WMFSmallButton(configuration: configuration, title: secondaryTitle, action: secondaryButtonAction)
                }
            }
            .padding(EdgeInsets(top: 12, leading: sizeClassPadding, bottom: 24, trailing: sizeClassPadding))
            .background {
                Color(appEnvironment.theme.paperBackground).ignoresSafeArea()
            }
        })
		
	}

    public var body: some View {
        content
            .background {
                Color(appEnvironment.theme.paperBackground).ignoresSafeArea()
            }
    }

}

#Preview {
	WMFOnboardingView(viewModel: .init(title: "Onboarding View", cells: [.init(icon: .add, title: "Title 1", subtitle: "Subtitle 1"), .init(icon: .checkmark, title: "Title 2", subtitle: "Subtitle 2")], primaryButtonTitle: "Primary Button", secondaryButtonTitle: "Secondary Button"))
}

import SwiftUI

public struct WMFOnboardingView: View {

    // MARK: - Properties

    var viewModel: WMFOnboardingViewModel
    var primaryButtonAction: (() -> Void)?
    var secondaryButtonAction: (() -> Void)?

    @ObservedObject var appEnvironment = WMFAppEnvironment.current

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var sizeClassPadding: CGFloat {
        horizontalSizeClass == .regular ? 40 : 16
    }

    @State private var flashScrollIndicators: Bool = false
    @State private var buttonAreaHeight: CGFloat = 0

    // MARK: - Scroll Content

    var scrollViewContent: some View {
        VStack {
            Text(viewModel.title)
                .font(Font(WMFFont.for(.boldTitle1)))
                .foregroundColor(Color(appEnvironment.theme.text))
                .padding(.bottom, 44)
                .padding(.top, 44 + sizeClassPadding)
                .multilineTextAlignment(.center)

            ForEach(1...viewModel.cells.count, id: \.self) { cell in
                VStack {
                    WMFOnboardingCell(viewModel: viewModel.cells[cell - 1])
                        .padding(.bottom, 24)
                }
            }
        }
        .padding(.horizontal, sizeClassPadding)
    }

    // MARK: - Buttons

    var buttonArea: some View {
        VStack(spacing: 20) {
            WMFLargeButton(
                configuration: .primary,
                title: viewModel.primaryButtonTitle,
                action: (viewModel.primaryButtonAction ?? primaryButtonAction)
            )
            .padding(.top, 16)

            if let secondaryTitle = viewModel.secondaryButtonTitle {
                let configuration = WMFSmallButton.Configuration(
                    style: .quiet,
                    trailingIcon: viewModel.secondaryButtonTrailingIcon
                )
                WMFSmallButton(configuration: configuration,
                               title: secondaryTitle,
                               action: (viewModel.secondaryButtonAction ?? secondaryButtonAction))
            }
        }
        .padding(EdgeInsets(top: 12,
                            leading: sizeClassPadding,
                            bottom: 24,
                            trailing: sizeClassPadding))
        .background(Color(appEnvironment.theme.paperBackground).ignoresSafeArea())
        .background(
            GeometryReader { proxy in
                Color.clear
                    .onAppear { buttonAreaHeight = proxy.size.height }
                    .onChange(of: proxy.size.height) { buttonAreaHeight = $0 }
            }
        )
    }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: true) {
                scrollViewContent
            }
            .scrollIndicatorsFlash(trigger: flashScrollIndicators)
            buttonArea
        }
        .background(Color(appEnvironment.theme.paperBackground).ignoresSafeArea())
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                flashScrollIndicators.toggle()
            }
        }
    }
}

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

    public var body: some View {
        ZStack {
            Color(appEnvironment.theme.paperBackground)
                .ignoresSafeArea()
            ScrollView(showsIndicators: true) {
                VStack {
                    Text(viewModel.title)
                        .font(Font(WKFont.for(.boldTitle1)))
                        .foregroundColor(Color(appEnvironment.theme.text))
                        .padding([.bottom, .top], 44)
                        .multilineTextAlignment(.center)
                    ForEach(1...viewModel.cells.count, id:\.self) { cell in
                        VStack {
                            WKOnboardingCell(viewModel: viewModel.cells[cell - 1])
                                .padding([.bottom, .trailing], 20)
                        }
                    }
                    Spacer()
                    
                    WKLargeButton(configuration: .primary, title: viewModel.primaryButtonTitle, action: primaryButtonAction)
                        .padding([.top], 16)

                    VStack {
                        if let secondaryTitle = viewModel.secondaryButtonTitle {
                            let configuration = WKSmallButton.Configuration(style: .quiet)
                            WKSmallButton(configuration: configuration, title: secondaryTitle, action: secondaryButtonAction)
                        }
                    }
                }
                .padding(sizeClassPadding)
            }
        }
    }
}

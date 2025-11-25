import SwiftUI

public struct WMFYearInReviewSlideHighlightShareableView: View {

    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    var theme: WMFTheme { appEnvironment.theme }

    public let viewModel: WMFYearInReviewSlideHighlightsViewModel

    public init(viewModel: WMFYearInReviewSlideHighlightsViewModel) {
        self.viewModel = viewModel
    }
    
    private var fontTraitOverride: UITraitCollection {
        UITraitCollection(preferredContentSizeCategory: .large)
    }
    
    private var rowFont: Font {
        Font(WMFFont.for(.helveticaBody, compatibleWith: fontTraitOverride))
    }
    
    private var footerFont: Font {
        Font(WMFFont.for(.body, compatibleWith: fontTraitOverride))
    }

    public var body: some View {
        ZStack {
            Color(uiColor: WMFColor.white)
                .ignoresSafeArea()
            VStack(spacing: 0) {
                VStack {
                    Spacer(minLength: 0)

                    infoboxView
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.horizontal, 35)

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                Text(viewModel.plaintextURL)
                    .font(footerFont)
                    .foregroundStyle(Color(uiColor: WMFColor.black))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 16)
            }
            .frame(maxWidth: 393)
            .frame(minHeight: 852)
            
        }
        .overlay(
            Rectangle()
                .stroke(Color(WMFColor.gray300), lineWidth: 1)
        )
    }

    private var infoboxView: some View {
        VStack(spacing: 24) {
            WMFYearInReviewInfoboxView(viewModel: viewModel.infoBoxViewModel, isSharing: true)
                .frame(maxWidth: 393)
        }
        .background(Color(WMFColor.gray100))
        .overlay(
            Rectangle()
                .stroke(Color(WMFColor.gray300), lineWidth: 1)
        )
    }
}

import SwiftUI
import WMFData

struct WMFYearInReviewSlideIntroV3View: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    private let viewModel: WMFYearInReviewIntroV3ViewModel
    
    private var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    private var sizeClassPadding: CGFloat {
        horizontalSizeClass == .regular ? 64 : 32
    }
    
    init(viewModel: WMFYearInReviewIntroV3ViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        
        ZStack(alignment: .bottom) {
            WMFYearInReviewScrollView(scrollViewContents: WMFYearInReviewSlideIntroV3ViewContent(viewModel: viewModel))
            
            VStack {
                WMFLargeButton(configuration: .primary, title: viewModel.primaryButtonTitle) {
                    withAnimation(.easeInOut(duration: 0.75)) {
                        viewModel.tappedPrimaryButton()
                    }
                }
                
                WMFLargeButton(configuration: .secondary, title: viewModel.secondaryButtonTitle) {
                    viewModel.tappedSecondaryButton()
                }
                
            }
            .padding(EdgeInsets(top: 12, leading: sizeClassPadding, bottom: 0, trailing: sizeClassPadding))
            .background {
                    Color(appEnvironment.theme.midBackground).ignoresSafeArea()
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            viewModel.onAppear()
        }
    }
}


fileprivate struct WMFYearInReviewSlideIntroV3ViewContent: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    let viewModel: WMFYearInReviewIntroV3ViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    private var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    private var sizeClassPadding: CGFloat {
        horizontalSizeClass == .regular ? 64 : 32
    }
    
    fileprivate init(viewModel: WMFYearInReviewIntroV3ViewModel) {
        self.viewModel = viewModel
    }
    
    @ScaledMetric private var bottomInset = 125.0
    
    var body: some View {
        
        VStack(spacing: 16) {
            VStack(spacing: 16) {
                ZStack {
                    Image(viewModel.gifName, bundle: .module)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                    WMFGIFImageView(viewModel.gifName)
                        .aspectRatio(1.5, contentMode: .fit)
                        .frame(maxWidth: .infinity)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(viewModel.altText)
            }
            
            VStack(alignment: .center, spacing: 75) {
                VStack(alignment: .center, spacing: 16) {
                    Text(viewModel.title)
                        .multilineTextAlignment(.center)
                        .font(Font(WMFFont.for(.boldTitle1)))
                        .foregroundColor(Color(uiColor: theme.text))
                    Text(viewModel.subtitle)
                        .multilineTextAlignment(.center)
                        .font(Font(WMFFont.for(.body)))
                        .foregroundColor(Color(uiColor: theme.text))
                }
                Text(viewModel.footer)
                    .multilineTextAlignment(.center)
                    .font(Font(WMFFont.for(.caption2)))
                    .foregroundColor(Color(uiColor: theme.secondaryText))
            }
            
            .padding(EdgeInsets(top: 0, leading: sizeClassPadding, bottom: bottomInset, trailing: sizeClassPadding))
        }
    }
}

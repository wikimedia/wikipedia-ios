import SwiftUI
import WMFData

struct WMFYearInReviewSlideIntroView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    private let viewModel: WMFYearInReviewIntroViewModel
    
    private var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    private var sizeClassPadding: CGFloat {
        horizontalSizeClass == .regular ? 64 : 32
    }
    
    init(viewModel: WMFYearInReviewIntroViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        
        ZStack(alignment: .bottom) {
            WMFYearInReviewScrollView(scrollViewContents: WMFYearInReviewSlideIntroViewContent(viewModel: viewModel))
            
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


fileprivate struct WMFYearInReviewSlideIntroViewContent: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    let viewModel: WMFYearInReviewIntroViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    private var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    private var sizeClassPadding: CGFloat {
        horizontalSizeClass == .regular ? 64 : 32
    }
    
    fileprivate init(viewModel: WMFYearInReviewIntroViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        
        VStack(spacing: 48) {
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
            
            VStack(alignment: .leading, spacing: 16) {
                Text(viewModel.title)
                    .font(Font(WMFFont.for(.boldTitle1)))
                Text(viewModel.subtitle)
                    .font(Font(WMFFont.for(.title3)))
            }
            .foregroundStyle(Color(uiColor: theme.text))
            .padding(EdgeInsets(top: 0, leading: sizeClassPadding, bottom: 0, trailing: sizeClassPadding))
        }
    }
}

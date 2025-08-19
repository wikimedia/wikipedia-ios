import SwiftUI
import WMFData

public struct WMFYearInReviewSlideLocationView: View {
    let viewModel: WMFYearInReviewSlideLocationViewModel
    
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    
    var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    public var body: some View {
        WMFYearInReviewScrollView(scrollViewContents: WMFYearInReviewSlideCategoryViewContent(viewModel: viewModel))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(uiColor: theme.midBackground))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

public struct WMFYearInReviewSlideCategoryViewContent: View {
    let viewModel: WMFYearInReviewSlideLocationViewModel
    
    public var body: some View {
        Text(viewModel.title)
    }
}

public struct WMFYearInReviewSlideStandardView: View {
    let viewModel: WMFYearInReviewSlideStandardViewModel
    
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    
    var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    public var body: some View {
        WMFYearInReviewScrollView(scrollViewContents: WMFYearInReviewSlideStandardViewContent(viewModel: viewModel))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(uiColor: theme.midBackground))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

public struct WMFYearInReviewSlideStandardViewContent: View {
    let viewModel: WMFYearInReviewSlideStandardViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    
    var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    var sizeClassPadding: CGFloat {
        horizontalSizeClass == .regular ? 64 : 32
    }
    
    private func subtitleAttributedString(subtitle: String) -> AttributedString {
        return (try? AttributedString(markdown: subtitle)) ?? AttributedString(subtitle)
    }
    
    public var body: some View {
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
            
            VStack(spacing: 16) {
                HStack(alignment: .top) {
                    Text(viewModel.title)
                        .font(Font(WMFFont.for(.boldTitle1)))
                        .foregroundStyle(Color(uiColor: theme.text))
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                    Spacer()
                    if let uiImage = WMFSFSymbolIcon.for(symbol: .infoCircleFill) {
                        Button {
                            viewModel.tappedInfo()
                        } label: {
                            Image(uiImage: uiImage)
                                .resizable()
                                .foregroundStyle(Color(uiColor: theme.icon))
                                .frame(width: 24, height: 24)
                                .alignmentGuide(.top) { dimensions in
                                    dimensions[.top] - 5
                                }
                        }
                    }
                }
                
                Text(subtitleAttributedString(subtitle: viewModel.subtitle))
                    .font(Font(WMFFont.for(.title3)))
                    .foregroundStyle(Color(uiColor: theme.text))
                    .accentColor(Color(uiColor: theme.link))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
            }
            .padding(EdgeInsets(top: 0, leading: sizeClassPadding, bottom: 0, trailing: sizeClassPadding))
        }
    }
}

struct WMFYearInReviewSlideIntroView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    let viewModel: WMFYearInReviewIntroViewModel
    
    var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    var sizeClassPadding: CGFloat {
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


private struct WMFYearInReviewSlideIntroViewContent: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    let viewModel: WMFYearInReviewIntroViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    var sizeClassPadding: CGFloat {
        horizontalSizeClass == .regular ? 64 : 32
    }
    
    init(viewModel: WMFYearInReviewIntroViewModel) {
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

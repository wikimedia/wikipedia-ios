import SwiftUI
import WebKit

public struct WMFYearInReviewView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: WMFYearInReviewViewModel

    var theme: WMFTheme {
        return appEnvironment.theme
    }

    public init(viewModel: WMFYearInReviewViewModel) {
        self.viewModel = viewModel
    }


    public var body: some View {
        NavigationView {
            VStack {
                WMFYearInReviewHeaderView(viewModel: viewModel)
                WMFYearInReviewBodyView(viewModel: viewModel)
            }
            .background(Color(uiColor: theme.midBackground))
            .toolbar {
                if !viewModel.isShowingIntro {
                    ToolbarItem(placement: .bottomBar) {
                        WMFYearInReviewToolbarView(viewModel: viewModel)
                    }
                }
            }
            Spacer()
        }
        .background(Color(uiColor: theme.midBackground))
        .navigationViewStyle(.stack)
        .environment(\.colorScheme, theme.preferredColorScheme)
        .frame(maxHeight: .infinity)
        .environment(\.openURL, OpenURLAction { url in
            viewModel.tappedLearnMore(url: url)
            return .handled
        })
    }

}

private struct WMFYearInReviewHeaderView: View {
    
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: WMFYearInReviewViewModel

    var theme: WMFTheme {
        return appEnvironment.theme
    }

    init(viewModel: WMFYearInReviewViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        HStack(alignment: .center) {
            if viewModel.shouldShowDonateButton {
                WMFYearInReviewDonateButton(viewModel: viewModel)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Spacer()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            Spacer()
            Image("W", bundle: .module)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 20)
                .foregroundColor(Color(theme.text))
                .accessibilityLabel(viewModel.localizedStrings.wIconAccessibilityLabel)
            Spacer()
            Button(action: {
                viewModel.tappedDone()
            }) {
                Text(viewModel.localizedStrings.doneButtonTitle)
                    .font(Font(WMFFont.navigationBarDoneButtonFont))
                    .foregroundColor(Color(theme.navigationBarTintColor))
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.bottom, 5)
        .padding([.top, .horizontal], 16)
    }
}

private struct WMFYearInReviewBodyView: View {
    
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: WMFYearInReviewViewModel
    
    var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    init(viewModel: WMFYearInReviewViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        if viewModel.isShowingIntro,
           let introViewModel = viewModel.introViewModel {
            WMFYearInReviewSlideIntroView(viewModel: introViewModel)
        } else {
            VStack {
                
                TabView(selection: $viewModel.currentSlideIndex) {
                    
                    ForEach(Array(viewModel.slides.enumerated()), id: \.offset) { index, slide in
                        if case .standard(let standardViewModel) = slide {
                            WMFYearInReviewSlideStandardView(viewModel: standardViewModel)
                        }
                        
                        if case .category(let categoryViewModel) = slide {
                            WMFYearInReviewSlideCategoryView(viewModel: categoryViewModel)
                        }
                    }
                    
                    
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .ignoresSafeArea(edges: .bottom)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct WMFYearInReviewToolbarView: View {
    
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: WMFYearInReviewViewModel
    
    var theme: WMFTheme {
        return appEnvironment.theme
    }
    
    init(viewModel: WMFYearInReviewViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        HStack(alignment: .center) {
            Button(action: {
                viewModel.tappedShare()
            }) {
                HStack(alignment: .center, spacing: 6) {
                    if let uiImage = WMFSFSymbolIcon.for(symbol: .share, font: .semiboldHeadline) {
                        Image(uiImage: uiImage)
                            .foregroundStyle(Color(uiColor: theme.link))
                    }
                    Text(viewModel.localizedStrings.shareButtonTitle)
                        .foregroundStyle(Color(uiColor: theme.link))
                }
                .font(Font(WMFFont.for(.semiboldHeadline)))
            }
            .frame(maxWidth: .infinity)
            Spacer()
            HStack(spacing: 9) {
                ForEach(0..<viewModel.slides.count, id: \.self) { index in
                    Circle()
                        .fill(index == viewModel.currentSlideIndex ? Color(uiColor: theme.link) : Color(uiColor: theme.link.withAlphaComponent(0.3)))
                        .frame(width: 7, height: 7)
                }
            }
            .frame(maxWidth: .infinity)
            Spacer()
            Button(action: {
                withAnimation {
                    viewModel.tappedNext()
                }
            }) {
                let text = viewModel.isLastSlide ? viewModel.localizedStrings.finishButtonTitle : viewModel.localizedStrings.nextButtonTitle
                Text(text)
                    .foregroundStyle(Color(uiColor: theme.link))
                    .font(Font(WMFFont.for(.semiboldHeadline)))
            }
            .frame(maxWidth: .infinity)
        }
    }
}

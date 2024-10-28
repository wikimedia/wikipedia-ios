import SwiftUI

public struct WMFYearInReview: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: WMFYearInReviewViewModel

    var theme: WMFTheme {
        return appEnvironment.theme
    }

    public var donePressed: (() -> Void)?

    public init(viewModel: WMFYearInReviewViewModel) {
        self.viewModel = viewModel
        UINavigationBar.appearance().backgroundColor = theme.midBackground
    }

    let configuration = WMFSmallButton.Configuration(style: .quiet, trailingIcon: nil)

    public var body: some View {
        NavigationView {
            VStack {
                HStack {
                    if viewModel.shouldShowDonate() {
                        WMFYearInReviewDonateButton(viewModel: viewModel)
                    }
                    Spacer()
                    Button(action: {
                        donePressed?()
                    }) {
                        Text(viewModel.localizedStrings.doneButtonTitle)
                            .foregroundStyle(Color(uiColor: theme.link))
                            .font(Font(WMFFont.for(.semiboldHeadline)))
                    }
                }
                .padding()
                if viewModel.isEdgeSlide && viewModel.currentSlide == 0 {
                    WMFYearInReviewScrollView(scrollViewContents: scrollViewContent, contents: { AnyView(buttonsFirstSlide) })
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.isEdgeSlide {
                    if viewModel.hasDonated {
                        WMFYearInReviewScrollView(scrollViewContents: scrollViewContent)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        WMFYearInReviewScrollView(scrollViewContents: scrollViewContent, contents: { AnyView(buttonsLastSlide) })
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                } else {
                    VStack {
                        TabView(selection: $viewModel.currentSlide) {
                            WMFSlideShow(currentSlide: $viewModel.currentSlide, slides: viewModel.slides)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                        .onChange(of: viewModel.currentSlide) { newSlide in
                            if newSlide == viewModel.slides.count - 1 {
                                viewModel.isEdgeSlide = true
                            } else {
                                viewModel.isEdgeSlide = false
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 48)
                    }
                    .ignoresSafeArea(edges: .bottom)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .background(Color(uiColor: theme.midBackground))
            .toolbar {
                if viewModel.shouldShowToolbar() { 
                    ToolbarItem(placement: .bottomBar) {
                        HStack(alignment: .center) {
                            Button(action: {
                                viewModel.handleShare(for: viewModel.currentSlide)
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
                                        .fill(index == viewModel.currentSlide ? Color(uiColor: theme.link) : Color(uiColor: theme.link.withAlphaComponent(0.3)))
                                        .frame(width: 7, height: 7)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            Spacer()
                            Button(action: {
                                withAnimation {
                                    viewModel.currentSlide = (viewModel.currentSlide + 1) % viewModel.slides.count
                                }
                            }) {
                                Text(viewModel.shouldShowFinish() ? viewModel.localizedStrings.finishButtonTitle : viewModel.localizedStrings.nextButtonTitle)
                                    .foregroundStyle(Color(uiColor: theme.link))
                                    .font(Font(WMFFont.for(.semiboldHeadline)))
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            Spacer()
        }
        .background(Color(uiColor: theme.midBackground))
        .navigationViewStyle(.stack)
        .environment(\.colorScheme, theme.preferredColorScheme)
        .frame(maxHeight: .infinity)
    }

    private var scrollViewContent: some View {
        VStack(spacing: 48) {
            // First slide
            if viewModel.currentSlide == 0 {
                VStack(alignment: .leading, spacing: 16) {
                    Image("globe", bundle: .module)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 48)
                    Text(viewModel.localizedStrings.firstSlideTitle)
                        .font(Font(WMFFont.for(.boldTitle1)))
                    Text(viewModel.localizedStrings.firstSlideSubtitle)
                        .font(Font(WMFFont.for(.title3)))
                }
                .foregroundStyle(Color(uiColor: theme.text))
                // Last slide
            } else {
                // Has donated or not
                if viewModel.hasDonated {
                    VStack(alignment: .leading, spacing: 16) {
                        Image("globe", bundle: .module)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 48)
                        Text(viewModel.localizedStrings.firstSlideTitle)
                            .font(Font(WMFFont.for(.boldTitle1)))
                        Text(viewModel.localizedStrings.firstSlideSubtitle)
                            .font(Font(WMFFont.for(.title3)))
                    }
                    .foregroundStyle(Color(uiColor: theme.text))
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        Image("globe", bundle: .module)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 48)
                        Text(viewModel.localizedStrings.firstSlideTitle)
                            .font(Font(WMFFont.for(.boldTitle1)))
                        Text(viewModel.localizedStrings.firstSlideSubtitle)
                            .font(Font(WMFFont.for(.title3)))
                    }
                    .foregroundStyle(Color(uiColor: theme.text))
                }
            }
        }
    }

    private var buttonsFirstSlide: some View {
        VStack {
            WMFLargeButton(configuration: .primary, title: viewModel.localizedStrings.firstSlideCTA) {
                withAnimation(.easeInOut(duration: 0.75)) {
                    viewModel.getStarted()
                }
            }
            WMFSmallButton(configuration: configuration, title: viewModel.localizedStrings.firstSlideHide) {
                // TODO: Implement hide this feature
            }
        }
    }
    
    private var buttonsLastSlide: some View {
        VStack {
            WMFLargeButton(configuration: .primary, title: viewModel.localizedStrings.lastSlideCTA) {
                withAnimation(.easeInOut(duration: 0.75)) {
                    // TODO: Implement this feature
                }
            }
            WMFSmallButton(configuration: configuration, title: viewModel.localizedStrings.lastSlideDonate) {
                // TODO: Implement this feature
            }
        }
    }
}

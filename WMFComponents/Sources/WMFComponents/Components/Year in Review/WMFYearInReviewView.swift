import SwiftUI

public struct WMFYearInReviewView: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: WMFYearInReviewViewModel

    var theme: WMFTheme {
        return appEnvironment.theme
    }

    public init(viewModel: WMFYearInReviewViewModel) {
        self.viewModel = viewModel
    }

    let configuration = WMFSmallButton.Configuration(style: .quiet, trailingIcon: nil)

    public var body: some View {
        NavigationView {
            VStack {
                HStack {
                    if viewModel.shouldShowDonateButton {
                        WMFYearInReviewDonateButton(viewModel: viewModel)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    if !viewModel.shouldShowDonateButton {
                        Spacer()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Spacer()
                    Image("W", bundle: .module)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(Color(theme.text))
                    Spacer()
                    Button(action: {
                        viewModel.logYearInReviewDidTapDone()
                        viewModel.handleDone()
                    }) {
                        Text(viewModel.localizedStrings.doneButtonTitle)
                            .foregroundStyle(Color(uiColor: theme.link))
                            .font(Font(WMFFont.for(.semiboldHeadline)))
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding()
                if viewModel.isFirstSlide {
                    WMFYearInReviewScrollView(
                        scrollViewContents: scrollViewContent,
                        contents: { AnyView(buttons) },
                        imageName: "intro",
                        imageOverlay: "globe_yir")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 48)
                        .onAppear {
                            viewModel.logYearInReviewSlideDidAppear()
                            viewModel.markFirstSlideAsSeen()
                        }

                } else {
                    VStack {
                        TabView(selection: $viewModel.currentSlide) {
                            WMFSlideShow(currentSlide: $viewModel.currentSlide, slides: viewModel.slides, infoAction: {
                                viewModel.handleInfo()
                            })
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 48)
                    }
                    .ignoresSafeArea(edges: .bottom)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onAppear {
                        viewModel.logYearInReviewSlideDidAppear()
                    }
                }
            }
            .background(Color(uiColor: theme.midBackground))
            .onChange(of: viewModel.currentSlide) { newSlide in
                // Logs slide impressions and next taps
                viewModel.logYearInReviewSlideDidAppear()
            }
            .toolbar {
                if !viewModel.isFirstSlide {
                    ToolbarItem(placement: .bottomBar) {
                        HStack(alignment: .center) {
                            Button(action: {
                                viewModel.handleShare(for: viewModel.currentSlide)
                                viewModel.logYearInReviewDidTapShare()
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
                                    viewModel.logYearInReviewSlideDidTapNext()
                                    viewModel.nextSlide()
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
            }
            Spacer()
        }
        .background(Color(uiColor: theme.midBackground))
        .navigationViewStyle(.stack)
        .environment(\.colorScheme, theme.preferredColorScheme)
        .frame(maxHeight: .infinity)
        .environment(\.openURL, OpenURLAction { url in
            viewModel.handleLearnMore(url: url)
            return .handled
        })
    }

    private var scrollViewContent: some View {
        VStack(spacing: 48) {
            VStack(alignment: .leading, spacing: 16) {
                Text(viewModel.localizedStrings.firstSlideTitle)
                    .font(Font(WMFFont.for(.boldTitle1)))
                Text(viewModel.localizedStrings.firstSlideSubtitle)
                    .font(Font(WMFFont.for(.title3)))
            }
            .foregroundStyle(Color(uiColor: theme.text))
        }
    }

    private var buttons: some View {
        VStack {
            WMFLargeButton(configuration: .primary, title: viewModel.localizedStrings.firstSlideCTA) {
                withAnimation(.easeInOut(duration: 0.75)) {
                    viewModel.loggingDelegate?.logYearInReviewIntroDidTapContinue()
                    viewModel.getStarted()
                }
            }
            WMFSmallButton(configuration: configuration, title: viewModel.localizedStrings.firstSlideLearnMore) {
                viewModel.loggingDelegate?.logYearInReviewIntroDidTapLearnMore()
                viewModel.coordinatorDelegate?.handleYearInReviewAction(.introLearnMore)
                // TODO: Implement hide this feature
            }
        }
    }
}


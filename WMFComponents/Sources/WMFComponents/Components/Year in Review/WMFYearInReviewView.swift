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
                        .accessibilityLabel(viewModel.localizedStrings.wIconAccessibilityLabel)
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
                        imageOverlayAccessibilityLabel: viewModel.localizedStrings.globeImageAccessibilityLabel,
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
                if newSlide == 1 {
                    viewModel.hasSeenTwoSlides = true
                }
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

            WMFLargeButton(configuration: .secondary, title: viewModel.localizedStrings.firstSlideLearnMore) {
                viewModel.loggingDelegate?.logYearInReviewIntroDidTapLearnMore()
                viewModel.coordinatorDelegate?.handleYearInReviewAction(.introLearnMore)
            }

        }
    }
}

struct GifImageView: UIViewRepresentable {
    private let name: String
    init(_ name: String) {
        self.name = name
    }
    
    func makeUIView(context: Context) -> WKWebView {
        print("Bundle path: \(Bundle.module.bundlePath)")
        if let urls = Bundle.module.urls(forResourcesWithExtension: "gif", subdirectory: "Resources") {
            print("Available resources: \(urls)")
        }

        let webview = WKWebView()

        if let url = Bundle.module.url(forResource: name, withExtension: "gif"),
           let gifData = try? Data(contentsOf: url) {
            webview.load(gifData, mimeType: "image/gif", characterEncodingName: "UTF-8", baseURL: url.deletingLastPathComponent())
        } else {
            print("Error: Could not find or load 'puppy.gif' in the bundle.")
        }

        return webview
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.reload()
    }
}

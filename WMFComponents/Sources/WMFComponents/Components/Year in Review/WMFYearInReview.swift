import SwiftUI

public struct WMFYearInReview: View {
    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @State private var currentSlide = 0
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
                if viewModel.isFirstSlide {
                    WMFYearInReviewFirstSlideView(scrollViewContents: scrollViewContent, contents: buttons)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    WMFSlideShow(currentSlide: $currentSlide, slides: viewModel.slides)
                }
            }
            .background(Color(uiColor: theme.midBackground))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        donePressed?()
                    }) {
                        Text(viewModel.localizedStrings.doneButtonTitle)
                            .foregroundStyle(Color(uiColor: theme.link))
                            .font(Font(WMFFont.for(.semiboldHeadline)))
                    }
                }
                if !viewModel.isFirstSlide {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(action: {
                            // TODO: Implement Donation
                        }) {
                            HStack {
                                if let uiImage = WMFSFSymbolIcon.for(symbol: .heartFilled, compatibleWith: UITraitCollection(preferredContentSizeCategory: .large)) {
                                    Image(uiImage: uiImage)
                                        .foregroundStyle(Color(uiColor: theme.destructive))
                                }
                                Text(viewModel.localizedStrings.donateButtonTitle)
                                    .foregroundStyle(Color(uiColor: theme.destructive))
                                    .font(Font(WMFFont.for(.semiboldHeadline)))
                            }
                        }
                    }
                    ToolbarItem(placement: .bottomBar) {
                        HStack {
                            Button(action: {
                                // TODO: Implement share
                            }) {
                                HStack(alignment: .center, spacing: 6) {
                                    Image(systemName: "square.and.arrow.up")
                                        .foregroundStyle(Color(uiColor: theme.link))
                                    Text(viewModel.localizedStrings.shareButtonTitle)
                                        .foregroundStyle(Color(uiColor: theme.link))
                                        .font(Font(WMFFont.for(.semiboldHeadline)))
                                }
                            }
                            Spacer()
                            Button(action: {
                                withAnimation {
                                    currentSlide = (currentSlide + 1) % viewModel.slides.count
                                }
                            }) {
                                Text(viewModel.localizedStrings.nextButtonTitle)
                                    .foregroundStyle(Color(uiColor: theme.link))
                                    .font(Font(WMFFont.for(.semiboldHeadline)))
                            }
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
        
    private var buttons: some View {
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
}

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
    }

    public var body: some View {
        NavigationView {
            VStack {
                if viewModel.isFirstSlide {
                    firstSlide
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

    private var firstSlide: some View {
        ScrollView {
            VStack(spacing: 48) {
                VStack(alignment: .leading, spacing: 16) {
                    Image("globe", bundle: .module)
                        .frame(maxWidth: .infinity, alignment: .center)
                    Text(viewModel.localizedStrings.firstSlideTitle)
                        .font(Font(WMFFont.for(.boldTitle1)))
                        .foregroundStyle(Color(uiColor: theme.text))
                    Text(viewModel.localizedStrings.firstSlideSubtitle)
                        .font(Font(WMFFont.for(.title3)))
                        .foregroundStyle(Color(uiColor: theme.text))
                }
                VStack {
                    Button(action: {
                        withAnimation {
                            viewModel.isFirstSlide = false
                        }
                    }) {
                        Text(viewModel.localizedStrings.firstSlideCTA)
                            .foregroundStyle(Color(uiColor: theme.paperBackground))
                            .padding(.vertical, 11)
                            .frame(maxWidth: .infinity)
                            .background(Color(uiColor: theme.link))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .font(Font(WMFFont.for(.semiboldHeadline)))
                    }
                    Button(action: {
                       // TODO: Implement hide this feature
                    }) {
                        Text(viewModel.localizedStrings.firstSlideHide)
                            .foregroundStyle(Color(uiColor: theme.link))
                            .padding(.vertical, 11)
                            .frame(maxWidth: .infinity)
                            .font(Font(WMFFont.for(.semiboldHeadline)))
                    }
                }
            }
        }
        .padding(36)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

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
                WMFSlideShow(currentSlide: $currentSlide, slides: viewModel.slides)
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
            Spacer()
        }
        .background(Color(uiColor: theme.midBackground))
        .navigationViewStyle(.stack)
        .environment(\.colorScheme, theme.preferredColorScheme)
        .frame(maxHeight: .infinity)
    }
}

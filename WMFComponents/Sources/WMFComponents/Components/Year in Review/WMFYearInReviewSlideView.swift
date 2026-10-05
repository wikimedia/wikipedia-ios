import SwiftUI

struct WMFYearInReviewSlideView: View {

    let slide: WMFYearInReviewSlideViewModel
    /// Called with the `isUIWhite` value of the frame, when the frame has one.
    var onUIWhiteRead: (@MainActor (Bool) -> Void)?
    @StateObject private var thumbnailLoader = WMFYearInReviewThumbnailLoader()

    var body: some View {
        ZStack {
            // This shows only until the Rive content loads.
            Color(uiColor: WMFYearInReviewViewModel.chromeBackgroundColor)
            content
        }
    }

    @ViewBuilder
    private var content: some View {
        if let animation = slide.animation {
            WMFRiveView(
                animation,
                text: slide.text,
                numbers: slide.numbers,
                images: thumbnailLoader.images,
                boolsToRead: [WMFYearInReviewViewModel.uiWhitePath],
                onBoolRead: { _, value in onUIWhiteRead?(value) },
                accessibilityLabel: slide.localizedStrings.accessibilityLabel
            )
            .task(id: slide.articleThumbnails) {
                await thumbnailLoader.load(slide.articleThumbnails)
            }
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        VStack(spacing: WMFSpacing.small) {
            Text(slide.id)
                .font(Font(WMFFont.for(.boldTitle1)))
            Text("no .riv yet")
                .font(Font(WMFFont.for(.caption1)))
                .opacity(0.6)
        }
        .foregroundStyle(Color(uiColor: slide.contentColor))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityHidden(true)
    }
}

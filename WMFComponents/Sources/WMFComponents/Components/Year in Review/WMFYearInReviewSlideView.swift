import SwiftUI

struct WMFYearInReviewSlideView: View {

    let slide: WMFYearInReviewSlideViewModel
    /// Called with the value of `slide.lightContentFlag` after the slide loads.
    var onLightContentFlag: (@MainActor (Bool) -> Void)? = nil
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
                accessibilityLabel: slide.localizedStrings.accessibilityLabel,
                readBool: slide.lightContentFlag,
                textFits: slide.textFits,
                onReadBool: onLightContentFlag
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

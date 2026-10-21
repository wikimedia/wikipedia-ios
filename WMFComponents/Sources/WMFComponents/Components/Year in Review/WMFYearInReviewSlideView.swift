import SwiftUI

struct WMFYearInReviewSlideView: View {

    let slide: WMFYearInReviewSlideViewModel
    /// Only the current slide plays. The pager builds the next slide before the reader swipes to it.
    var isCurrent: Bool = true
    /// Called with the value of `slide.lightContentFlag` after the slide loads.
    var onLightContentFlag: (@MainActor (Bool) -> Void)? = nil
    var donateButtonTitle: String = ""
    var isLoadingDonate: Bool = false
    /// Called with the frame of the primary donate button in window coordinates.
    var onTapDonate: (@MainActor (@escaping @MainActor () -> CGRect) -> Void)? = nil
    @StateObject private var thumbnailLoader = WMFYearInReviewThumbnailLoader()
    @State private var donateButtonFrame: CGRect = .zero

    var body: some View {
        ZStack {
            // This shows only until the Rive content loads.
            Color(uiColor: WMFYearInReviewViewModel.chromeBackgroundColor)
            if slide.showsPrimaryDonateButton {
                // The button goes below the animation, so that it does not cover the artwork.
                VStack(spacing: 0) {
                    content
                    donateButton
                }
                .background(Color(uiColor: WMFTheme.light.paperBackground))
            } else {
                content
            }
        }
    }

    /// Same style as the explore button on the announcement.
    private var donateButton: some View {
        ZStack {
            WMFSmallButton(
                configuration: .init(style: .primary),
                title: donateButtonTitle,
                forceBackgroundColor: WMFTheme.light.link,
                forceForegroundColor: WMFTheme.light.paperBackground,
                action: {
                    let frame = donateButtonFrame
                    onTapDonate? { frame }
                }
            )
            .opacity(isLoadingDonate ? 0 : 1)
            .disabled(isLoadingDonate)

            if isLoadingDonate {
                ProgressView()
            }
        }
        .onGeometryChange(for: CGRect.self) { proxy in
            proxy.frame(in: .global)
        } action: { frame in
            donateButtonFrame = frame
        }
        .padding(.vertical, WMFSpacing.medium)
    }

    @ViewBuilder
    private var content: some View {
        if let animation = slide.animation {
            WMFRiveView(
                animation,
                text: slide.text,
                numbers: slide.numbers,
                images: slide.images.merging(thumbnailLoader.images) { _, loaded in loaded },
                layoutDirection: slide.layoutDirection,
                accessibilityLabel: slide.localizedStrings.accessibilityLabel,
                isPlaying: isCurrent,
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

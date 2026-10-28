import SwiftUI

struct WMFYearInReviewSlideView: View {

    let slide: WMFYearInReviewSlideViewModel
    /// Only the current slide plays. The pager builds the next slide before the reader swipes to it.
    var isCurrent: Bool = true
    /// Called with the value of `slide.lightContentFlag` after the slide loads.
    var onLightContentFlag: (@MainActor (Bool) -> Void)? = nil
    /// False while VoiceOver runs. The pager then shows `slide.answer` as the next slide, because a
    /// VoiceOver reader cannot tap an answer in the .riv.
    var showsAnswerInPlace: Bool = true
    var donateButtonTitle: String = ""
    var isLoadingDonate: Bool = false
    /// Called with the frame of the primary donate button in window coordinates.
    var onTapDonate: (@MainActor (@escaping @MainActor () -> CGRect) -> Void)? = nil
    @StateObject private var thumbnailLoader = WMFYearInReviewThumbnailLoader()
    @State private var donateButtonFrame: CGRect = .zero
    /// True after the .riv fires `slide.answerTrigger`. It goes back to false when the slide is no
    /// longer current, so the reader sees the first state again when they come back.
    @State private var isShowingAnswer = false

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
            // The answer loads with the slide, under it, so it is ready when the reader taps.
            ZStack {
                if let answer, let answerAnimation = answer.animation {
                    riveView(answer, animation: answerAnimation, isShown: isShowingAnswer)
                }
                riveView(slide, animation: animation, isShown: !isShowingAnswer)
            }
            .task(id: articleThumbnails) {
                await thumbnailLoader.load(articleThumbnails)
            }
            .onChange(of: isCurrent) {
                if !isCurrent {
                    isShowingAnswer = false
                }
            }
        } else {
            placeholder
        }
    }

    private var answer: WMFYearInReviewSlideViewModel? {
        showsAnswerInPlace ? slide.answer : nil
    }

    private var articleThumbnails: [WMFRiveImage: WMFYearInReviewSlideViewModel.ArticleThumbnail] {
        slide.articleThumbnails.merging(answer?.articleThumbnails ?? [:]) { first, _ in first }
    }

    /// A state that is not shown does not play. When it shows again, it plays from its first frame.
    private func riveView(_ state: WMFYearInReviewSlideViewModel, animation: WMFRiveAnimation, isShown: Bool) -> some View {
        let isAnswer = state.id != slide.id
        let loadedImages: [WMFRiveImage: Data] = thumbnailLoader.images.filter { state.articleThumbnails[$0.key] != nil }
        let images: [WMFRiveImage: Data] = state.images.merging(loadedImages) { _, loaded in loaded }
        let readBool: WMFRiveBool? = isAnswer ? nil : state.lightContentFlag
        var onReadBool: (@MainActor (Bool) -> Void)?
        if !isAnswer {
            onReadBool = onLightContentFlag
        }
        let watchedTrigger: WMFRiveTrigger? = (answer == nil || isAnswer) ? nil : state.answerTrigger
        let onAnswerTrigger: @MainActor () -> Void = {
            guard isCurrent, answer != nil else { return }
            isShowingAnswer = true
        }
        return WMFRiveView(
            animation,
            text: state.text,
            numbers: state.numbers,
            bools: state.bools,
            images: images,
            layoutDirection: state.layoutDirection,
            accessibilityLabel: state.localizedStrings.accessibilityLabel,
            isPlaying: isCurrent && isShown,
            readBool: readBool,
            textFits: state.textFits,
            onReadBool: onReadBool,
            watchedTrigger: watchedTrigger,
            missingImageFlags: state.missingImageFlags,
            onWatchedEvent: onAnswerTrigger
        )
        .opacity(isShown ? 1 : 0)
        .accessibilityHidden(!isShown)
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

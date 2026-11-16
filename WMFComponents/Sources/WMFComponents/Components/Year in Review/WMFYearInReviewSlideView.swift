import SwiftUI

struct WMFYearInReviewSlideView: View {

    let slide: WMFYearInReviewSlideViewModel
    /// Only the current slide plays. The pager builds the next slide before the reader swipes to it.
    var isCurrent: Bool = true
    /// `false` shows only the background. Each Rive view holds screen-sized Metal buffers, so the
    /// pager loads only the slides near the current one when it builds all slides at once.
    var loadsAnimation: Bool = true
    /// Called with the value of `slide.lightContentFlag` after the slide loads.
    var onLightContentFlag: (@MainActor (Bool) -> Void)? = nil
    var accessibilityFocus: AccessibilityFocusState<String?>.Binding? = nil
    var onAccessibilityScroll: (@MainActor (Edge) -> Void)? = nil
    var accessibilityScrollHint: String = ""
    /// A VoiceOver reader cannot tap a card in the .riv. A double tap on the slide shows the answer.
    var revealAccessibilityHint: String = ""
    var onAnswerShown: (@MainActor () -> Void)? = nil
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
        if !loadsAnimation {
            Color(uiColor: WMFYearInReviewViewModel.chromeBackgroundColor)
                .accessibilityHidden(true)
        } else if let animation = slide.animation {
            // The answer loads with the slide, under it, so it is ready when the reader taps.
            ZStack {
                if let answer, let answerAnimation = answer.animation {
                    riveView(answer, animation: answerAnimation, isShown: isShowingAnswer)
                }
                riveView(slide, animation: animation, isShown: !isShowingAnswer)
            }
            .modifier(answerSlideAccessibility)
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
        slide.answer
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
            onAnswerShown?()
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
            onReadBool: onReadBool,
            watchedTrigger: watchedTrigger,
            missingImageFlags: state.missingImageFlags,
            onWatchedEvent: onAnswerTrigger
        )
        .opacity(isShown ? 1 : 0)
        .accessibilityHidden(!isShown)
        .modifier(
            WMFYearInReviewSlideFocusModifier(
                // The slide and its answer are then one element. See `combinesAnswerForVoiceOver`.
                focus: combinesAnswerForVoiceOver ? nil : accessibilityFocus,
                id: state.id,
                onScroll: onAccessibilityScroll,
                hint: accessibilityScrollHint,
                onActivate: nil
            )
        )
    }

    private var answerSlideAccessibility: WMFYearInReviewAnswerSlideAccessibilityModifier {
        let shownState: WMFYearInReviewSlideViewModel = (isShowingAnswer ? answer : nil) ?? slide
        var onActivate: (@MainActor () -> Void)?
        if !isShowingAnswer {
            onActivate = revealAnswerForVoiceOver
        }
        let focus = WMFYearInReviewSlideFocusModifier(
            focus: accessibilityFocus,
            id: slide.id,
            onScroll: onAccessibilityScroll,
            hint: isShowingAnswer ? accessibilityScrollHint : revealAccessibilityHint,
            onActivate: onActivate
        )
        return WMFYearInReviewAnswerSlideAccessibilityModifier(
            isEnabled: combinesAnswerForVoiceOver,
            label: shownState.localizedStrings.accessibilityLabel ?? "",
            focus: focus
        )
    }

    /// While VoiceOver runs (`onAccessibilityScroll` is set), a slide and its answer are one element
    /// whose label changes. VoiceOver kept the focus on the slide after the double tap and read
    /// its old label, so a focus move to a second element did not work.
    private var combinesAnswerForVoiceOver: Bool {
        answer != nil && onAccessibilityScroll != nil
    }

    /// Shows the answer without the exit animation of the .riv. VoiceOver does not read a label
    /// that changes on the focused element, so the answer is announced.
    private func revealAnswerForVoiceOver() {
        guard isCurrent, !isShowingAnswer, let label = answer?.localizedStrings.accessibilityLabel else { return }
        isShowingAnswer = true
        onAnswerShown?()
        Task { @MainActor in
            // After the sound that VoiceOver plays for the double tap.
            try? await Task.sleep(for: .milliseconds(100))
            AccessibilityNotification.Announcement(label).post()
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

private struct WMFYearInReviewSlideFocusModifier: ViewModifier {

    let focus: AccessibilityFocusState<String?>.Binding?
    let id: String
    let onScroll: (@MainActor (Edge) -> Void)?
    let hint: String
    let onActivate: (@MainActor () -> Void)?

    @ViewBuilder
    func body(content: Content) -> some View {
        if let focus, let onScroll, let onActivate {
            content
                .accessibilityFocused(focus, equals: id)
                .accessibilityScrollAction { edge in onScroll(edge) }
                .accessibilityHint(hint)
                .accessibilityAction { onActivate() }
        } else if let focus, let onScroll {
            content
                .accessibilityFocused(focus, equals: id)
                .accessibilityScrollAction { edge in onScroll(edge) }
                .accessibilityHint(hint)
        } else if let focus {
            content.accessibilityFocused(focus, equals: id)
        } else {
            content
        }
    }
}

private struct WMFYearInReviewAnswerSlideAccessibilityModifier: ViewModifier {

    let isEnabled: Bool
    let label: String
    let focus: WMFYearInReviewSlideFocusModifier

    @ViewBuilder
    func body(content: Content) -> some View {
        if isEnabled {
            content
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(label)
                .modifier(focus)
        } else {
            content
        }
    }
}

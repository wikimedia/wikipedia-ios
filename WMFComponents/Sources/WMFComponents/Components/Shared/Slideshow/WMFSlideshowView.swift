import SwiftUI

/// A titled, horizontally paged carousel of illustrated cards over a primary and an optional secondary action.
public struct WMFSlideshowView: View {

    // MARK: - Properties

    @ObservedObject var appEnvironment = WMFAppEnvironment.current
    @ObservedObject var viewModel: WMFSlideshowViewModel

    var primaryAction: (@MainActor @Sendable () -> Void)?
    var secondaryAction: (@MainActor @Sendable () -> Void)?

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @ScaledMetric private var buttonSpacing: CGFloat = 8

    private static let maximumDynamicTypeSize: DynamicTypeSize = .accessibility2

    private enum Metrics {
        static let compactHorizontalPadding: CGFloat = 16
        static let regularHorizontalPadding: CGFloat = 40

        static let slidePeek: CGFloat = 32
        static let slideSpacing: CGFloat = 8

        static let titleTopPadding: CGFloat = 8
        static let titleBottomPadding: CGFloat = 20
        static let dotSize: CGFloat = 6
        static let dotSpacing: CGFloat = 6
        static let dotsVerticalPadding: CGFloat = 16
        static let buttonAreaTopPadding: CGFloat = 12
        static let bottomPadding: CGFloat = 16
        static let stackedSlideSpacing: CGFloat = 16
    }

    // MARK: - Lifecycle

    public init(viewModel: WMFSlideshowViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Derived Values

    private var theme: WMFTheme {
        appEnvironment.theme
    }

    private var resolvedDynamicTypeSize: DynamicTypeSize {
        min(dynamicTypeSize, Self.maximumDynamicTypeSize)
    }

    private var horizontalPadding: CGFloat {
        horizontalSizeClass == .regular ? Metrics.regularHorizontalPadding : Metrics.compactHorizontalPadding
    }

    private func slideWidth(forContainerLength length: CGFloat) -> CGFloat {
        max(0, length + horizontalPadding - Metrics.slidePeek - Metrics.slideSpacing)
    }

    private var showsDots: Bool {
        viewModel.slides.count > 1 && !resolvedDynamicTypeSize.isAccessibilitySize
    }

    // MARK: - Body

    public var body: some View {
        content
            .dynamicTypeSize(...Self.maximumDynamicTypeSize)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(uiColor: theme.paperBackground).ignoresSafeArea())
            .onAppear {
                reportSlideOnScreen()
            }
            .onChange(of: viewModel.currentSlideID) { _, _ in
                reportSlideOnScreen()
            }
    }

    @ViewBuilder
    private var content: some View {
        if resolvedDynamicTypeSize.isAccessibilitySize {
            stackedContent
        } else {
            carouselContent
        }
    }

    private var carouselContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            carousel

            if showsDots {
                dots
            }

            buttons
        }
    }


    private var stackedContent: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: Metrics.stackedSlideSpacing) {
                    header

                    ForEach(viewModel.slides) { slide in
                        WMFSlideView(slide: slide, fillsAvailableHeight: false)
                            .padding(.horizontal, horizontalPadding)
                    }
                }
                .padding(.bottom, Metrics.stackedSlideSpacing)
            }
            .scrollBounceBehavior(.basedOnSize)
            .clipped()

            buttons
                .zIndex(1)
        }
    }

    // MARK: - Header

    private var header: some View {
        Text(viewModel.localizedStrings.title)
            .font(Font(WMFFont.for(.boldTitle1, sized: resolvedDynamicTypeSize)))
            .foregroundStyle(Color(uiColor: theme.text))
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, Metrics.titleTopPadding)
            .padding(.bottom, Metrics.titleBottomPadding)
            .padding(.horizontal, horizontalPadding)
            .accessibilityAddTraits(.isHeader)
    }

    // MARK: - Carousel

    private var carousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Metrics.slideSpacing) {
                ForEach(viewModel.slides) { slide in
                    WMFSlideView(slide: slide)
                        .containerRelativeFrame(.horizontal) { length, _ in
                            slideWidth(forContainerLength: length)
                        }
                        .accessibilityValue(Text(viewModel.accessibilityValue(for: slide) ?? ""))
                }
            }
            .scrollTargetLayout()
        }
        .contentMargins(.horizontal, horizontalPadding, for: .scrollContent)
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $viewModel.currentSlideID)
        .scrollBounceBehavior(.basedOnSize)
        .frame(maxHeight: .infinity)
    }

    // MARK: - Page Dots

    private var dots: some View {
        HStack(spacing: Metrics.dotSpacing) {
            ForEach(viewModel.slides) { slide in
                Circle()
                    .fill(slide.id == viewModel.currentSlide?.id
                          ? Color(uiColor: theme.link)
                          : Color(uiColor: theme.secondaryText).opacity(0.3))
                    .frame(width: Metrics.dotSize, height: Metrics.dotSize)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, Metrics.dotsVerticalPadding)
        .accessibilityHidden(true)
    }

    // MARK: - Buttons

    private var buttons: some View {
        VStack(spacing: buttonSpacing) {
            WMFLargeButton(style: .primary, title: viewModel.localizedStrings.primaryButtonTitle) {
                tappedPrimary()
            }

            if let secondaryButtonTitle = viewModel.localizedStrings.secondaryButtonTitle {
                WMFSmallButton(configuration: .init(style: .quiet), title: secondaryButtonTitle) {
                    tappedSecondary()
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, horizontalPadding)
        .padding(.top, Metrics.buttonAreaTopPadding)
        .padding(.bottom, Metrics.bottomPadding)
        .background(Color(uiColor: theme.paperBackground).ignoresSafeArea())
    }

    // MARK: - Actions

    private func tappedPrimary() {
        (viewModel.primaryAction ?? primaryAction)?()
    }

    private func tappedSecondary() {
        (viewModel.secondaryAction ?? secondaryAction)?()
    }

    // MARK: - Logging

    private func reportSlideOnScreen() {
        guard let slide = viewModel.currentSlide else { return }

        viewModel.didShowSlide?(slide)
    }
}

// MARK: - Previews

private extension WMFSlideshowViewModel {

    static func preview(slideCount: Int = 4, showsCloseButton: Bool = true) -> WMFSlideshowViewModel {
        let slides: [Slide] = [
            .init(
                id: "year-in-review",
                image: WMFSFSymbolIcon.for(symbol: .clock, font: .xxlTitleBold),
                backgroundColor: WMFColor.beige300,
                title: "See your [X] reading days come together in Year in Review",
                subtitle: "Once a year, your reading days come back as a look at where the year took you, ready to share."
            ),
            .init(
                id: "saved",
                image: WMFSFSymbolIcon.for(symbol: .bookmarkFill, font: .xxlTitleBold),
                backgroundColor: WMFColor.green100,
                title: "Sync your [X] saved articles",
                subtitle: "Log in to your Wikipedia account to allow your saved articles to be synced across devices."
            ),
            .init(
                id: "activity",
                image: WMFSFSymbolIcon.for(symbol: .globeAmericas, font: .xxlTitleBold),
                backgroundColor: WMFColor.blue100,
                title: "Revisit your [X] recent reads with Activity",
                subtitle: "See your reading time, explored topics, and the reach of your contributions in the Activity tab."
            ),
            .init(
                id: "edits",
                image: WMFSFSymbolIcon.for(symbol: .pencil, font: .xxlTitleBold),
                backgroundColor: WMFColor.green100,
                title: "Get credit for your edits",
                subtitle: "Build a track record you can be proud of, with contributions across Wikimedia projects credited to your account."
            )
        ]

        return WMFSlideshowViewModel(
            localizedStrings: .init(
                title: "Wikipedia is better with an account",
                primaryButtonTitle: "Create account",
                secondaryButtonTitle: "Maybe later",
                closeButtonAccessibilityLabel: "Close",
                slidePositionAccessibilityValue: { position, total in "\(position) of \(total)" }
            ),
            slides: Array(slides.prefix(slideCount)),
            showsCloseButton: showsCloseButton,
            closeAction: { },
            primaryAction: { },
            secondaryAction: { }
        )
    }
}

#Preview("Slideshow") {
    WMFSlideshowView(viewModel: .preview())
}

#Preview("Slideshow - Single Slide") {
    WMFSlideshowView(viewModel: .preview(slideCount: 1, showsCloseButton: false))
}

#Preview("Slideshow - Accessibility Text Size") {
    WMFSlideshowView(viewModel: .preview())
        .dynamicTypeSize(.accessibility3)
}

#Preview("Slideshow - Dark") {
    WMFSlideshowView(viewModel: .preview())
        .onAppear {
            WMFAppEnvironment.current.set(theme: .dark)
        }
}

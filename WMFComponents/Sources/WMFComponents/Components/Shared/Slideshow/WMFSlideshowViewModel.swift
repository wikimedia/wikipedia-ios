import UIKit

/// Drives `WMFSlideshowView`: a titled set of illustrated cards with a primary and an optional secondary action.
@MainActor
public final class WMFSlideshowViewModel: ObservableObject {

    // MARK: - Nested Types

    public struct LocalizedStrings {

        public var title: String
        public var primaryButtonTitle: String
        public var secondaryButtonTitle: String?
        public var closeButtonAccessibilityLabel: String?

        /// Takes a slide's one-based position and the slide count, e.g. "2 of 4".
        public var slidePositionAccessibilityValue: ((Int, Int) -> String)?

        public init(
            title: String,
            primaryButtonTitle: String,
            secondaryButtonTitle: String? = nil,
            closeButtonAccessibilityLabel: String? = nil,
            slidePositionAccessibilityValue: ((Int, Int) -> String)? = nil
        ) {
            self.title = title
            self.primaryButtonTitle = primaryButtonTitle
            self.secondaryButtonTitle = secondaryButtonTitle
            self.closeButtonAccessibilityLabel = closeButtonAccessibilityLabel
            self.slidePositionAccessibilityValue = slidePositionAccessibilityValue
        }
    }

    public struct Slide: Identifiable {

        /// The default is unique per instance, so pass a stable value when the slides are rebuilt
        /// while on screen, otherwise the carousel loses its place.
        public let id: String

        public var image: UIImage?

        /// The card's text color is derived from this tint, so one pastel reads in either theme.
        public var backgroundColor: UIColor?

        public var title: String
        public var subtitle: String?
        public var accessibilityIdentifier: String?

        public init(
            id: String = UUID().uuidString,
            image: UIImage? = nil,
            backgroundColor: UIColor? = nil,
            title: String,
            subtitle: String? = nil,
            accessibilityIdentifier: String? = nil
        ) {
            self.id = id
            self.image = image
            self.backgroundColor = backgroundColor
            self.title = title
            self.subtitle = subtitle
            self.accessibilityIdentifier = accessibilityIdentifier
        }
    }

    // MARK: - Properties

    @Published public var localizedStrings: LocalizedStrings
    @Published public var slides: [Slide]
    @Published public var currentSlideID: String?

    /// Overrides the app theme, for a caller that draws its own palette rather than following `WMFAppEnvironment`.
    public var theme: WMFTheme?

    public var showsCloseButton: Bool
    public var closeAction: (() -> Void)?
    public var primaryAction: (() -> Void)?
    public var secondaryAction: (() -> Void)?

    /// Called with each slide as it comes on screen, including the first one, for impression logging.
    public var didShowSlide: ((Slide) -> Void)?

    // MARK: - Lifecycle

    public init(
        localizedStrings: LocalizedStrings,
        slides: [Slide],
        currentSlideID: String? = nil,
        theme: WMFTheme? = nil,
        showsCloseButton: Bool = true,
        closeAction: (() -> Void)? = nil,
        primaryAction: (() -> Void)? = nil,
        secondaryAction: (() -> Void)? = nil,
        didShowSlide: ((Slide) -> Void)? = nil
    ) {
        self.localizedStrings = localizedStrings
        self.slides = slides
        self.currentSlideID = currentSlideID ?? slides.first?.id
        self.theme = theme
        self.showsCloseButton = showsCloseButton
        self.closeAction = closeAction
        self.primaryAction = primaryAction
        self.secondaryAction = secondaryAction
        self.didShowSlide = didShowSlide
    }

    // MARK: - Slide Position

    /// Falls back to the first slide, because `scrollPosition` only reports one once the user scrolls.
    public var currentSlide: Slide? {
        guard let currentSlideID,
              let slide = slides.first(where: { $0.id == currentSlideID }) else {
            return slides.first
        }

        return slide
    }

    public var currentSlideIndex: Int {
        guard let currentSlide,
              let index = slides.firstIndex(where: { $0.id == currentSlide.id }) else {
            return 0
        }

        return index
    }

    public func accessibilityValue(for slide: Slide) -> String? {
        guard let slidePositionAccessibilityValue = localizedStrings.slidePositionAccessibilityValue,
              let index = slides.firstIndex(where: { $0.id == slide.id }) else {
            return nil
        }

        return slidePositionAccessibilityValue(index + 1, slides.count)
    }

    public func advanceToNextSlide() {
        guard !slides.isEmpty else { return }

        let nextIndex = (currentSlideIndex + 1) % slides.count
        currentSlideID = slides[nextIndex].id
    }

    public func advanceToPreviousSlide() {
        guard !slides.isEmpty else { return }

        let previousIndex = (currentSlideIndex - 1 + slides.count) % slides.count
        currentSlideID = slides[previousIndex].id
    }
}

import SwiftUI
import Combine

// MARK: - Slide Model

public enum WMFYiR2026SlideContent {
    /// Full-bleed image/animation with centred text overlay
    case content(WMFYiR2026ContentSlideData)
    /// 3-4 option interactive quiz/poll card
    case interactive(WMFYiR2026InteractiveSlideData)
}

public struct WMFYiR2026ContentSlideData: Identifiable {
    public let id: UUID
    /// Name of the Lottie file in the bundle (no extension — .lottie or .json)
    public let lottieName: String?
    /// Fallback image name if no Lottie animation is provided
    public let imageName: String?
    /// Accent/overlay tint – used for gradient and text shadow
    public let accentColor: Color
    public let headline: String
    public let body: String

    public init(id: UUID = UUID(),
                lottieName: String? = nil,
                imageName: String? = nil,
                accentColor: Color,
                headline: String,
                body: String) {
        self.id = id
        self.lottieName = lottieName
        self.imageName = imageName
        self.accentColor = accentColor
        self.headline = headline
        self.body = body
    }
}

public struct WMFYiR2026InteractiveSlideData: Identifiable {
    public let id: UUID
    public let lottieName: String?
    public let accentColor: Color
    public let question: String
    public let options: [WMFYiR2026Option]

    public init(id: UUID = UUID(),
                lottieName: String? = nil,
                accentColor: Color,
                question: String,
                options: [WMFYiR2026Option]) {
        self.id = id
        self.lottieName = lottieName
        self.accentColor = accentColor
        self.question = question
        self.options = options
    }
}

public struct WMFYiR2026Option: Identifiable {
    public let id: UUID
    public let label: String
    public let emoji: String?

    public init(id: UUID = UUID(), label: String, emoji: String? = nil) {
        self.id = id
        self.label = label
        self.emoji = emoji
    }
}

// MARK: - Slide Wrapper

public struct WMFYiR2026Slide: Identifiable {
    public let id: UUID
    public let content: WMFYiR2026SlideContent

    public init(content: WMFYiR2026SlideContent) {
        self.id = UUID()
        self.content = content
    }
}

// MARK: - ViewModel

@MainActor
public final class WMFYiR2026ViewModel: ObservableObject {

    // MARK: Published state

    @Published public private(set) var currentIndex: Int = 0
    @Published public private(set) var slides: [WMFYiR2026Slide] = []
    /// Which option index the user selected on each interactive slide (keyed by slide id)
    @Published public private(set) var selections: [UUID: Int] = [:]
    /// Controls the animated progress bar segments at the top
    @Published public private(set) var segmentProgress: [CGFloat] = []

    // MARK: Story-bar timer

    private var storyTimer: AnyCancellable?
    /// How long each content slide auto-advances (seconds). Interactive slides pause until answered.
    public let contentSlideDuration: TimeInterval = 6.0
    private let timerInterval: TimeInterval = 0.05
    @Published public private(set) var activeSegmentFill: CGFloat = 0

    // MARK: Init

    public init() {
        slides = Self.makeSampleSlides()
        segmentProgress = Array(repeating: 0, count: slides.count)
        startTimer()
    }

    // MARK: Navigation

    public func advance() {
        guard currentIndex < slides.count - 1 else { return }
        completeCurrentSegment()
        currentIndex += 1
        activeSegmentFill = 0
        startTimer()
    }

    public func retreat() {
        guard currentIndex > 0 else { return }
        resetCurrentSegment()
        currentIndex -= 1
        segmentProgress[currentIndex] = 0
        activeSegmentFill = 0
        startTimer()
    }

    public func selectOption(slideID: UUID, optionIndex: Int) {
        selections[slideID] = optionIndex
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 900_000_000)
            advance()
        }
    }

    // MARK: Story bar helpers

    private func startTimer() {
        storyTimer?.cancel()
        guard case .content = slides[currentIndex].content else { return }

        storyTimer = Timer.publish(every: timerInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                let step = CGFloat(self.timerInterval / self.contentSlideDuration)
                self.activeSegmentFill = min(self.activeSegmentFill + step, 1.0)
                if self.activeSegmentFill >= 1.0 {
                    self.advance()
                }
            }
    }

    private func completeCurrentSegment() {
        storyTimer?.cancel()
        segmentProgress[currentIndex] = 1.0
    }

    private func resetCurrentSegment() {
        storyTimer?.cancel()
        segmentProgress[currentIndex] = 0
        activeSegmentFill = 0
    }

    // MARK: Sample data
    //
    // Animation files available in WMFComponents/Lotties:
    //   bg_shooting_star.lottie — star field, good for intro/outro
    //   reading_book.lottie     — open book, article count slides
    //   pencil_write.lottie     — writing, good for interactive/quiz slides
    //   bg3.lottie              — abstract background, general content slides

    private static func makeSampleSlides() -> [WMFYiR2026Slide] {
        [
            WMFYiR2026Slide(content: .content(.init(
                lottieName: "bg_shooting_star",
                accentColor: Color(red: 0.08, green: 0.08, blue: 0.20),
                headline: "Your 2026\nin Review",
                body: "You explored the world through Wikipedia this year."
            ))),
            WMFYiR2026Slide(content: .content(.init(
                lottieName: "reading_book",
                accentColor: Color(red: 0.55, green: 0.25, blue: 0.70),
                headline: "4,200 Articles\nRead",
                body: "You were in the top 3% of Wikipedia readers globally."
            ))),
            WMFYiR2026Slide(content: .interactive(.init(
                lottieName: "pencil_write",
                accentColor: Color(red: 0.85, green: 0.40, blue: 0.10),
                question: "What was your most-read topic this year?",
                options: [
                    .init(label: "Science & Technology", emoji: "🔬"),
                    .init(label: "History & Culture",    emoji: "🏛️"),
                    .init(label: "Geography",             emoji: "🌍"),
                    .init(label: "Sports & Games",        emoji: "⚽")
                ]
            ))),
            WMFYiR2026Slide(content: .content(.init(
                lottieName: "bg3",
                accentColor: Color(red: 0.10, green: 0.55, blue: 0.45),
                headline: "12 Languages\nExplored",
                body: "From English to Swahili, your curiosity knows no borders."
            ))),
            WMFYiR2026Slide(content: .interactive(.init(
                lottieName: "pencil_write",
                accentColor: Color(red: 0.70, green: 0.15, blue: 0.35),
                question: "How do you mainly use Wikipedia?",
                options: [
                    .init(label: "Quick fact-checks",  emoji: "⚡"),
                    .init(label: "Deep dives",          emoji: "🏊"),
                    .init(label: "Settling arguments",  emoji: "🤝"),
                    .init(label: "Just browsing",       emoji: "👀")
                ]
            ))),
            WMFYiR2026Slide(content: .content(.init(
                lottieName: "bg_shooting_star",
                accentColor: Color(red: 0.08, green: 0.08, blue: 0.20),
                headline: "Thanks for\nbeing curious.",
                body: "See you in 2027. Keep exploring."
            )))
        ]
    }
}

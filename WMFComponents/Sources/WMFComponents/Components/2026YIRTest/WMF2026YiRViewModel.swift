import SwiftUI

// MARK: - Slide Model

public enum WMFYiR2026SlideContent {
    /// Full-bleed image/animation with centred text overlay
    case content(WMFYiR2026ContentSlideData)
    /// Text options quiz/poll card with optional correct answer
    case interactive(WMFYiR2026InteractiveSlideData)
    /// Image-based quiz — tap one of the image tiles
    case imageQuiz(WMFYiR2026ImageQuizSlideData)
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
    /// Index into `options` that is the correct answer. nil = poll (no right/wrong).
    public let correctOptionIndex: Int?

    public init(id: UUID = UUID(),
                lottieName: String? = nil,
                accentColor: Color,
                question: String,
                options: [WMFYiR2026Option],
                correctOptionIndex: Int? = nil) {
        self.id = id
        self.lottieName = lottieName
        self.accentColor = accentColor
        self.question = question
        self.options = options
        self.correctOptionIndex = correctOptionIndex
    }
}

// MARK: - Image Quiz Slide

public struct WMFYiR2026ImageOption: Identifiable {
    public let id: UUID
    /// Remote URL string (Wikimedia Commons etc.) — takes priority over imageName.
    public let imageURL: String?
    /// Local asset name or SF Symbol fallback when imageURL is nil or fails to load.
    public let imageName: String?
    /// Whether this is the correct answer.
    public let isCorrect: Bool

    public init(id: UUID = UUID(), imageURL: String? = nil, imageName: String? = nil, isCorrect: Bool) {
        self.id = id
        self.imageURL = imageURL
        self.imageName = imageName
        self.isCorrect = isCorrect
    }
}

public struct WMFYiR2026ImageQuizSlideData: Identifiable {
    public let id: UUID
    public let lottieName: String?
    public let accentColor: Color
    public let question: String
    public let options: [WMFYiR2026ImageOption]

    public init(id: UUID = UUID(),
                lottieName: String? = nil,
                accentColor: Color,
                question: String,
                options: [WMFYiR2026ImageOption]) {
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
    public let subtitle: String?
    /// SF Symbol or asset name for the thumbnail. Optional.
    public let imageName: String?
    /// Per-option card background color. Falls back to white.opacity(0.15) if nil.
    public let optionColor: Color?

    public init(
        id: UUID = UUID(),
        label: String,
        subtitle: String? = nil,
        imageName: String? = nil,
        optionColor: Color? = nil
    ) {
        self.id = id
        self.label = label
        self.subtitle = subtitle
        self.imageName = imageName
        self.optionColor = optionColor
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

    @Published public var currentIndex: Int = 0
    @Published public private(set) var slides: [WMFYiR2026Slide] = []
    /// Which option index the user selected on each interactive slide (keyed by slide id)
    @Published public private(set) var selections: [UUID: Int] = [:]
    /// Whether the last navigation was a retreat — used to flip slide transition direction
    @Published public private(set) var isRetreating: Bool = false

    // MARK: Init

    public init() {
        slides = Self.makeSampleSlides()
    }

    // MARK: Navigation

    public func advance() {
        guard currentIndex < slides.count - 1 else { return }
        isRetreating = false
        currentIndex += 1
    }

    public func retreat() {
        guard currentIndex > 0 else { return }
        isRetreating = true
        currentIndex -= 1
    }

    public func selectOption(slideID: UUID, optionIndex: Int) {
        selections[slideID] = optionIndex
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
                    .init(label: "Science & Technology", subtitle: "Physics, space & more",  optionColor: Color(red: 0.25, green: 0.45, blue: 0.85)),
                    .init(label: "History & Culture",    subtitle: "People & civilizations",  optionColor: Color(red: 0.85, green: 0.55, blue: 0.15)),
                    .init(label: "Geography",            subtitle: "Places around the world", optionColor: Color(red: 0.20, green: 0.65, blue: 0.45)),
                    .init(label: "Sports & Games",       subtitle: "Athletics & competition",  optionColor: Color(red: 0.75, green: 0.25, blue: 0.35))
                ]
                // No correctOptionIndex — this is a poll, no right/wrong
            ))),
            WMFYiR2026Slide(content: .imageQuiz(.init(
                lottieName: "bg3",
                accentColor: Color(red: 0.05, green: 0.45, blue: 0.40),
                question: "Which of these appeared in your most-visited article?",
                options: [
                    .init(imageURL: "https://upload.wikimedia.org/wikipedia/commons/9/99/Welsh_Pembroke_Corgi.jpg",         isCorrect: false),
                    .init(imageURL: "https://upload.wikimedia.org/wikipedia/commons/0/0e/Dolina-dolnej-wisly-2.jpg",        isCorrect: true),
                    .init(imageURL: "https://upload.wikimedia.org/wikipedia/commons/3/34/Pommes_d_amour.jpg",              isCorrect: false),
                    .init(imageURL: "https://upload.wikimedia.org/wikipedia/commons/f/f2/Shipwreck_of_the_SS_American_Star_on_the_shore_of_Fuerteventura.jpg", isCorrect: false)
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
                question: "Wikipedia was founded in which year?",
                options: [
                    .init(label: "1999", subtitle: "Two years before the web boom",  optionColor: Color(red: 0.25, green: 0.45, blue: 0.85)),
                    .init(label: "2001", subtitle: "The year of the iPod",            optionColor: Color(red: 0.85, green: 0.55, blue: 0.15)),
                    .init(label: "2004", subtitle: "Same year as Facebook",           optionColor: Color(red: 0.20, green: 0.65, blue: 0.45)),
                    .init(label: "2007", subtitle: "Year of the first iPhone",        optionColor: Color(red: 0.75, green: 0.25, blue: 0.35))
                ],
                correctOptionIndex: 1  // 2001 is correct
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

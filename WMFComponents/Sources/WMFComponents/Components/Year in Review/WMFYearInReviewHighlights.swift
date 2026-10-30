import Foundation

/// The highlights of a personalized Year in Review, drawn on the image that "Share highlights" on the
/// end screen shares. Each highlight is `nil` (or empty) when the reader does not have it.
public struct WMFYearInReviewHighlights: Sendable {

    public struct LocalizedStrings: Sendable {
        public let title: String
        public let articlesReadLabel: String
        public let minutesReadLabel: String
        public let rotationLabel: String
        public let rabbitHoleLabel: String
        public let nicheCategoryLabel: String
        public let createdWith: String

        public init(title: String, articlesReadLabel: String, minutesReadLabel: String, rotationLabel: String, rabbitHoleLabel: String, nicheCategoryLabel: String, createdWith: String) {
            self.title = title
            self.articlesReadLabel = articlesReadLabel
            self.minutesReadLabel = minutesReadLabel
            self.rotationLabel = rotationLabel
            self.rabbitHoleLabel = rabbitHoleLabel
            self.nicheCategoryLabel = nicheCategoryLabel
            self.createdWith = createdWith
        }
    }

    /// The first and the last article of the longest rabbit hole.
    public struct RabbitHole: Sendable, Equatable {
        public let firstTitle: String
        public let lastTitle: String

        public init(firstTitle: String, lastTitle: String) {
            self.firstTitle = firstTitle
            self.lastTitle = lastTitle
        }
    }

    /// With fewer highlights than this, "Share highlights" does not show.
    public static let minimumHighlightCount = 2

    /// The image lists at most this number of articles in the rotation.
    public static let maximumRotationCount = 3

    public let articlesRead: Int?
    public let minutesRead: Int?
    /// At most `maximumRotationCount`, most visited first.
    public let rotation: [String]
    public let rabbitHole: RabbitHole?
    public let nicheCategory: String?
    public let localizedStrings: LocalizedStrings

    public init(articlesRead: Int?, minutesRead: Int?, rotation: [String], rabbitHole: RabbitHole?, nicheCategory: String?, localizedStrings: LocalizedStrings) {
        self.articlesRead = articlesRead
        self.minutesRead = minutesRead
        self.rotation = Array(rotation.prefix(Self.maximumRotationCount))
        self.rabbitHole = rabbitHole
        self.nicheCategory = nicheCategory
        self.localizedStrings = localizedStrings
    }

    /// The number of highlights on the image, out of 5.
    public var highlightCount: Int {
        [articlesRead != nil, minutesRead != nil, !rotation.isEmpty, rabbitHole != nil, nicheCategory != nil]
            .filter { $0 }
            .count
    }

    public var isShareable: Bool {
        highlightCount >= Self.minimumHighlightCount
    }
}

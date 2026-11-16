import Foundation

/// How often the Discover reading list regenerates. Matches the Android update frequency.
public enum WMFDiscoverCadence: String, Codable, Sendable, CaseIterable {
    case daily
    case weekly
    case monthly
}

/// Where the Discover reading list takes its seed articles from. Matches the Android source setting.
public enum WMFDiscoverSource: String, Codable, Sendable, CaseIterable {
    case interests
    case saved
    case history
}

/// The reader's Discover preferences. Stored locally and never synced, like on Android.
public struct WMFDiscoverSettings: Codable, Sendable, Equatable {

    public static let articleCountRange = 1...20
    public static let defaultArticleCount = 5

    public static let `default` = WMFDiscoverSettings(
        isEnabled: false,
        articleCount: defaultArticleCount,
        cadence: .weekly,
        source: .interests
    )

    public var isEnabled: Bool

    /// The number of articles in each generated list. Kept inside `articleCountRange`.
    public var articleCount: Int {
        didSet {
            articleCount = Self.clamped(articleCount)
        }
    }

    public var cadence: WMFDiscoverCadence
    public var source: WMFDiscoverSource

    public init(isEnabled: Bool, articleCount: Int, cadence: WMFDiscoverCadence, source: WMFDiscoverSource) {
        self.isEnabled = isEnabled
        self.articleCount = Self.clamped(articleCount)
        self.cadence = cadence
        self.source = source
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? Self.default.isEnabled
        let articleCount = try container.decodeIfPresent(Int.self, forKey: .articleCount) ?? Self.default.articleCount
        let cadence = try container.decodeIfPresent(WMFDiscoverCadence.self, forKey: .cadence) ?? Self.default.cadence
        let source = try container.decodeIfPresent(WMFDiscoverSource.self, forKey: .source) ?? Self.default.source
        self.init(isEnabled: isEnabled, articleCount: articleCount, cadence: cadence, source: source)
    }

    private static func clamped(_ articleCount: Int) -> Int {
        min(max(articleCount, articleCountRange.lowerBound), articleCountRange.upperBound)
    }
}

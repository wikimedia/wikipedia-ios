import Foundation

/// A topic an article belongs to, as classified by the Page Content Service, alongside its confidence score.
/// Topic names come from a language-independent taxonomy, e.g. "Biography.Women" or "STEM.Biology".
public struct WMFPageTopic: Sendable, Hashable {
    public let topic: String
    public let score: Double

    public init(topic: String, score: Double) {
        self.topic = topic
        self.score = score
    }
}

/// An aggregate of how much of a user's reading in a given period fell under a particular topic.
public struct WMFTopicReadingSummary: Sendable, Hashable {
    public let topic: String

    /// Number of distinct articles read in the period that belong to this topic. An article read
    /// repeatedly counts once.
    public let articleCount: Int

    /// Total seconds spent reading those articles in the period.
    public let timeSpentSeconds: Int

    public init(topic: String, articleCount: Int, timeSpentSeconds: Int) {
        self.topic = topic
        self.articleCount = articleCount
        self.timeSpentSeconds = timeSpentSeconds
    }
}

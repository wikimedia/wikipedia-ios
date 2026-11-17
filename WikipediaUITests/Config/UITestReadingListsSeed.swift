import Foundation

/// The saved articles and reading lists a test wants on device before launch.
/// Mirrors `UITestReadingListsSeed` in the app, which decodes it from the launch arguments.
struct UITestReadingListsSeed: Codable {
    struct ReadingList: Codable {
        let name: String
        let description: String?
        let createdMinutesAgo: Int
    }

    struct Article: Codable {
        let title: String
        let description: String?
        let snippet: String?
        let savedMinutesAgo: Int
        let readingListNames: [String]
    }

    let readingLists: [ReadingList]
    let articles: [Article]

    /// No saved articles and no reading lists. Launching with it clears what earlier tests left behind.
    static let empty = UITestReadingListsSeed(readingLists: [], articles: [])

    /// Base64 keeps the JSON out of the launch-argument plist parsing.
    var launchArgumentValue: String {
        guard let data = try? JSONEncoder().encode(self) else {
            preconditionFailure("UITestReadingListsSeed must encode to JSON.")
        }
        return data.base64EncodedString()
    }
}

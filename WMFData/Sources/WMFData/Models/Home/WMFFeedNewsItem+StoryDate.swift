import Foundation

public extension WMFFeedNewsItem {

    /// The month and day of the story, at midnight UTC. The year of the date is not valid.
    ///
    /// The story HTML starts with a comment that holds the date, for example `<!--Aug 12-->`.
    var storyMonthAndDay: Date? {
        return WMFFeedNewsItem.monthAndDay(fromStoryHTML: story)
    }

    private static let dateRegex = try? NSRegularExpression(pattern: "^(?:<!--)(:?[^-]+)(?:-->)", options: [])

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en")
        formatter.dateFormat = "MMM dd"
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        formatter.calendar = calendar
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

    static func monthAndDay(fromStoryHTML storyHTML: String?) -> Date? {
        guard let storyHTML, let regex = dateRegex,
              let match = regex.firstMatch(in: storyHTML, options: [], range: NSRange(storyHTML.startIndex..., in: storyHTML)),
              let range = Range(match.range(at: 1), in: storyHTML) else {
            return nil
        }
        return dateFormatter.date(from: String(storyHTML[range]))
    }
}

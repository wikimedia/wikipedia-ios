import Foundation

extension DateFormatter {
    static let mediaWikiAPIDateFormatter: DateFormatter = {
        let iso8601Format = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        dateFormatter.dateFormat = iso8601Format
        return dateFormatter
    }()
}

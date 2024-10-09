import Foundation

public class WMFYearInReviewSlide: Identifiable {
    public let year: Int
    public let title: String
    public let isCollective: Bool
    public var id: String? {
        return "\(year)-\(title)-\(UUID())"
    }
    public var evaluated: Bool
    public var display: Bool
    public var data: Data? // Codable

    public init(year: Int, title: String, isCollective: Bool, evaluated: Bool, display: Bool, data: Data? = nil) {
        self.year = year
        self.title = title
        self.isCollective = isCollective
        self.evaluated = evaluated
        self.display = display
        self.data = data
    }
}

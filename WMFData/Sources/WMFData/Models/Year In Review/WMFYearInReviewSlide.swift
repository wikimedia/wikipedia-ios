import Foundation

public class WMFYearInReviewSlide: Identifiable {
    public let year: Int
    public let id: WMFYearInReviewPersonalizedSlideID
    public var evaluated: Bool
    public var display: Bool
    public var data: Data?

    init(year: Int, id: WMFYearInReviewPersonalizedSlideID, evaluated: Bool, display: Bool, data: Data? = nil) {
        self.year = year
        self.id = id
        self.evaluated = evaluated
        self.display = display
        self.data = data
    }
}

public enum WMFYearInReviewPersonalizedSlideID: String, Comparable {
    case readCount
    case editCount
    case donateCount
    case mostReadDay

    public static func < (lhs: WMFYearInReviewPersonalizedSlideID, rhs: WMFYearInReviewPersonalizedSlideID) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

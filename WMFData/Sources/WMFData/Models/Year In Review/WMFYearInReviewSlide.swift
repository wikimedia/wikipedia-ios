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

// TEMP: Remove
public enum WMFYearInReviewPersonalizedSlideID: String {
    case readCount
    case editCount
}

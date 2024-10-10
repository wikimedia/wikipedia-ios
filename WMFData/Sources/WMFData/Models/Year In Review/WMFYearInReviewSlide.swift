import Foundation

public class WMFYearInReviewSlide: Identifiable {
    public let year: Int
    public let slideId: WMFYearInReviewPersonalizedSlideID
    public var evaluated: Bool
    public var display: Bool
    public var data: Data?

    public init(year: Int, evaluated: Bool, display: Bool, data: Data? = nil) {
        self.year = year
        self.evaluated = evaluated
        self.display = display
        self.data = data
    }
}

//TEMP
public enum WMFYearInReviewPersonalizedSlideID: String {
    case readCount
    case editCount
}

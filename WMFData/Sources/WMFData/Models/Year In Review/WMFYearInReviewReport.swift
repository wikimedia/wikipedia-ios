import Foundation

public class WMFYearInReviewReport: Identifiable {
    public let year: Int
    public var slides: [WMFYearInReviewSlide]

    public init(year: Int, slides: [WMFYearInReviewSlide]) {
        self.year = year
        self.slides = slides
    }

}

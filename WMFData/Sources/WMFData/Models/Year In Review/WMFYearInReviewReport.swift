import Foundation

public class WMFYearInReviewReport: Identifiable {
    public let year: Int

    public var slides: [WMFYearInReviewSlide] // check if needs to be var

    public init(year: Int, version: Int, slides: [WMFYearInReviewSlide]) {
        self.year = year
        self.slides = slides
    }

}

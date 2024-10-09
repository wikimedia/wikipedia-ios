import Foundation

public class WMFYearInReviewReport: Identifiable {
    public let year: Int
    public let version: Int
    public var id: String {
        return "\(year)-\(version)-\(UUID())"
    }
    public var slides: [WMFYearInReviewSlide] // check if needs to be var

    public init(year: Int, version: Int, slides: [WMFYearInReviewSlide]) {
        self.year = year
        self.version = version
        self.slides = slides
    }

}

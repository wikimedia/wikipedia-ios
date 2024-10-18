import Foundation

public class WMFYearInReviewReport: Identifiable {
    public let year: Int
    public let slides: [WMFYearInReviewSlide]
    
    public init(year: Int, slides: [WMFYearInReviewSlide]) {
        self.year = year
        self.slides = slides
    }

    init(cdReport: CDYearInReviewReport) {
        let year = Int(cdReport.year)
        self.year = year
        
        guard let cdSlides = cdReport.slides as? Set<CDYearInReviewSlide> else {
            self.slides = []
            return
        }
        
        self.slides = cdSlides.compactMap({ cdSlide in
            
            guard let cdSlideID = cdSlide.id,
                  let slideID = WMFYearInReviewPersonalizedSlideID(rawValue: cdSlideID) else {
                return nil
            }
            
            return WMFYearInReviewSlide(year: year, id: slideID, evaluated: cdSlide.evaluated, display: cdSlide.display)
            
        })
    }
}

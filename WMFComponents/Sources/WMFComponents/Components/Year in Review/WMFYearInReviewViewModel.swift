import Foundation
import SwiftUI

public class WMFYearInReviewViewModel: ObservableObject {
    @Published var isFirstSlide = true
    @Published var slides: [YearInReviewSlide]
    let localizedStrings: LocalizedStrings
    var slides: [YearInReviewSlideContent]
    
    public init(localizedStrings: LocalizedStrings, slides: [YearInReviewSlideContent]) {
        self.localizedStrings = localizedStrings
        self.slides = slides
    }
    
    public func getStarted() {
        isFirstSlide = false
    }
    
    public func updateSlide(at index: Int, with newSlide: YearInReviewSlide) {
        print("updating")
        guard index >= 0 && index < slides.count else {
            return
        }
        slides[index] = newSlide
    }
    
    public struct LocalizedStrings {
        let donateButtonTitle: String
        let doneButtonTitle: String
        let shareButtonTitle: String
        let nextButtonTitle: String
        let firstSlideTitle: String
        let firstSlideSubtitle: String
        let firstSlideCTA: String
        let firstSlideHide: String
        
        public init(donateButtonTitle: String, doneButtonTitle: String, shareButtonTitle: String, nextButtonTitle: String, firstSlideTitle: String, firstSlideSubtitle: String, firstSlideCTA: String, firstSlideHide: String) {
            self.donateButtonTitle = donateButtonTitle
            self.doneButtonTitle = doneButtonTitle
            self.shareButtonTitle = shareButtonTitle
            self.nextButtonTitle = nextButtonTitle
            self.firstSlideTitle = firstSlideTitle
            self.firstSlideSubtitle = firstSlideSubtitle
            self.firstSlideCTA = firstSlideCTA
            self.firstSlideHide = firstSlideHide
        }
    }
}

public struct YearInReviewSlideContent: SlideShowProtocol {
    public let imageName: String
    public let title: String
    let informationBubbleText: String?
    public let subtitle: String
    
    public init(imageName: String, title: String, informationBubbleText: String?, subtitle: String) {
        self.imageName = imageName
        self.title = title
        self.informationBubbleText = informationBubbleText
        self.subtitle = subtitle
    }
}

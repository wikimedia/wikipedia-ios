import Foundation
import SwiftUI

public protocol WMFYearInReviewLoggingDelegate: AnyObject {
    func logYearInReviewIntroDidAppear()
    func logYearInReviewDidTapDone(slideLoggingID: String)
    func logYearInReviewIntroDidTapContinue()
    func logYearInReviewIntroDidTapDisable()
}

public class WMFYearInReviewViewModel: ObservableObject {
    @Published var isFirstSlide = true
    @Published var currentSlide = 0
    let localizedStrings: LocalizedStrings
    var slides: [YearInReviewSlideContent]
    private(set) weak var loggingDelegate: WMFYearInReviewLoggingDelegate?
    
    public init(localizedStrings: LocalizedStrings, slides: [YearInReviewSlideContent], loggingDelegate: WMFYearInReviewLoggingDelegate) {
        self.localizedStrings = localizedStrings
        self.slides = slides
        self.loggingDelegate = loggingDelegate
    }
    
    public func getStarted() {
        isFirstSlide = false
    }
    
    public func nextSlide() {
        currentSlide = (currentSlide + 1) % slides.count
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
    
    public func logYearInReviewDidTapDone() {
        let slideLoggingID: String
        if isFirstSlide {
            slideLoggingID = "start"
        } else {
            slideLoggingID = slides[currentSlide].loggingID
        }
        loggingDelegate?.logYearInReviewDidTapDone(slideLoggingID: slideLoggingID)
    }
}

public struct YearInReviewSlideContent: SlideShowProtocol {
    public let imageName: String
    public let title: String
    let informationBubbleText: String?
    public let subtitle: String
    public let loggingID: String
    
    public init(imageName: String, title: String, informationBubbleText: String?, subtitle: String, loggingID: String) {
        self.imageName = imageName
        self.title = title
        self.informationBubbleText = informationBubbleText
        self.subtitle = subtitle
        self.loggingID = loggingID
    }
}

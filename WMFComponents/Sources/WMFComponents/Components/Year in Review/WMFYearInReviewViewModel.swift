import Foundation
import SwiftUI

public class WMFYearInReviewViewModel: ObservableObject {
    let localizedStrings: LocalizedStrings
    var slides: [YearInReviewSlide]
    
    public init(localizedStrings: LocalizedStrings, slides: [YearInReviewSlide]) {
        self.localizedStrings = localizedStrings
        self.slides = slides
    }
    
    public struct LocalizedStrings {
        let donateButtonTitle: String
        let doneButtonTitle: String
        let shareButtonTitle: String
        let nextButtonTitle: String
        
        public init(donateButtonTitle: String, doneButtonTitle: String, shareButtonTitle: String, nextButtonTitle: String) {
            self.donateButtonTitle = donateButtonTitle
            self.doneButtonTitle = doneButtonTitle
            self.shareButtonTitle = shareButtonTitle
            self.nextButtonTitle = nextButtonTitle
        }
    }
}

public struct YearInReviewSlide {
    let imageName: String
    let title: String
    let informationBubbleText: String?
    let subtitle: String
    
    public init(imageName: String, title: String, informationBubbleText: String?, subtitle: String) {
        self.imageName = imageName
        self.title = title
        self.informationBubbleText = informationBubbleText
        self.subtitle = subtitle
    }
}

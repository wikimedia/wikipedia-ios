import Foundation

struct WMFYearInReviewSlideStandardViewModel: WMFYearInReviewSlideViewModelProtocol {
    
    enum SubtitleType {
        case html
        case markdown
        case standard
    }
    
    let gifName: String
    let altText: String
    let title: String
    let subtitle: String
    let subtitleType: SubtitleType
    let loggingID: String
    let tappedInfo: () -> Void
    
    init(gifName: String, altText: String, title: String, subtitle: String, subtitleType: SubtitleType = .standard, loggingID: String, tappedInfo: @escaping () -> Void) {
        self.gifName = gifName
        self.altText = altText
        self.title = title
        self.subtitle = subtitle
        self.subtitleType = subtitleType
        self.loggingID = loggingID
        self.tappedInfo = tappedInfo
    }
}

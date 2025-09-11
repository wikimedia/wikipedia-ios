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
    var infoURL: URL?
    let forceHideDonateButton: Bool
    let loggingID: String
    let tappedLearnMore: ((URL) -> Void)?
    let tappedInfo: () -> Void
    
    init(gifName: String, altText: String, title: String, subtitle: String, subtitleType: SubtitleType = .standard, infoURL: URL?, forceHideDonateButton: Bool, loggingID: String, tappedLearnMore: ((URL) -> Void)? = nil, tappedInfo: @escaping () -> Void) {
        self.gifName = gifName
        self.altText = altText
        self.title = title
        self.subtitle = subtitle
        self.subtitleType = subtitleType
        self.infoURL = infoURL
        self.forceHideDonateButton = forceHideDonateButton
        self.loggingID = loggingID
        self.tappedLearnMore = tappedLearnMore
        self.tappedInfo = tappedInfo
    }
}

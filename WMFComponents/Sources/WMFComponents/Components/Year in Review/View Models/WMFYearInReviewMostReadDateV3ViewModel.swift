import Foundation

struct WMFYearInReviewSlideMostReadDateV3ViewModel {
    let gifName: String
    let altText: String
    let title: String
    let time: String
    let timeFooter: String
    let day: String
    let dayFooter: String
    let month: String
    let monthFooter: String
    var infoURL: URL?
    let forceHideDonateButton: Bool
    let loggingID: String
    let tappedLearnMore: ((URL) -> Void)?
    let tappedInfo: () -> Void
    
    init(gifName: String, altText: String, title: String, time: String, timeFooter: String, day: String, dayFooter: String, month: String, monthFooter: String, infoURL: URL? = nil, forceHideDonateButton: Bool, loggingID: String, tappedLearnMore: ((URL) -> Void)? = nil, tappedInfo: @escaping () -> Void) {
        self.gifName = gifName
        self.altText = altText
        self.title = title
        self.time = time
        self.timeFooter = timeFooter
        self.day = day
        self.dayFooter = dayFooter
        self.month = month
        self.monthFooter = monthFooter
        self.infoURL = infoURL
        self.forceHideDonateButton = forceHideDonateButton
        self.loggingID = loggingID
        self.tappedLearnMore = tappedLearnMore
        self.tappedInfo = tappedInfo
    }
}

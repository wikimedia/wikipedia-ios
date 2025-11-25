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
    let loggingID: String
    let tappedInfo: () -> Void
    
    init(gifName: String, altText: String, title: String, time: String, timeFooter: String, day: String, dayFooter: String, month: String, monthFooter: String, loggingID: String, tappedInfo: @escaping () -> Void) {
        self.gifName = gifName
        self.altText = altText
        self.title = title
        self.time = time
        self.timeFooter = timeFooter
        self.day = day
        self.dayFooter = dayFooter
        self.month = month
        self.monthFooter = monthFooter
        self.loggingID = loggingID
        self.tappedInfo = tappedInfo
    }
}

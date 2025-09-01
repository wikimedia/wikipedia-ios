struct WMFYearInReviewSlideLocationViewModel {
    
    let title: String
    let loggingID: String
    
    init(localizedStrings: WMFYearInReviewViewModel.LocalizedStrings, loggingID: String) {
        self.title = localizedStrings.locationTitle
        self.loggingID = loggingID
    }
}

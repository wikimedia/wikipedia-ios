struct WMFYearInReviewIntroV2ViewModel {
    let gifName: String
    let altText: String
    let title: String
    let subtitle: String
    let primaryButtonTitle: String
    let secondaryButtonTitle: String
    let loggingID: String
    let onAppear: () -> Void
    let tappedPrimaryButton: () -> Void
    let tappedSecondaryButton: () -> Void
    
    init(gifName: String, altText: String, title: String, subtitle: String, primaryButtonTitle: String, secondaryButtonTitle: String, loggingID: String, onAppear: @escaping () -> Void, tappedPrimaryButton: @escaping () -> Void, tappedSecondaryButton: @escaping () -> Void) {
        self.gifName = gifName
        self.altText = altText
        self.title = title
        self.subtitle = subtitle
        self.primaryButtonTitle = primaryButtonTitle
        self.secondaryButtonTitle = secondaryButtonTitle
        self.loggingID = loggingID
        self.onAppear = onAppear
        self.tappedPrimaryButton = tappedPrimaryButton
        self.tappedSecondaryButton = tappedSecondaryButton
    }
}

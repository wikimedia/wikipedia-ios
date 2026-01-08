import SwiftUI

struct WMFYearInReviewIntroV3ViewModel {
    let gifName: String
    let altText: String
    let title: String
    let subtitle: String
    let footer: String
    let primaryButtonTitle: String
    let secondaryButtonTitle: String
    let loggingID: String
    let onAppear: () -> Void
    let tappedPrimaryButton: () -> Void
    let tappedSecondaryButton: () -> Void
    
    init(gifName: String, altText: String, title: String, subtitle: String, footer: String, primaryButtonTitle: String, secondaryButtonTitle: String, loggingID: String, onAppear: @escaping () -> Void, tappedPrimaryButton: @escaping () -> Void, tappedSecondaryButton: @escaping () -> Void) {
        self.gifName = gifName
        self.altText = altText
        self.title = title
        self.subtitle = subtitle
        self.footer = footer
        self.primaryButtonTitle = primaryButtonTitle
        self.secondaryButtonTitle = secondaryButtonTitle
        self.loggingID = loggingID
        self.onAppear = onAppear
        self.tappedPrimaryButton = tappedPrimaryButton
        self.tappedSecondaryButton = tappedSecondaryButton
    }
}

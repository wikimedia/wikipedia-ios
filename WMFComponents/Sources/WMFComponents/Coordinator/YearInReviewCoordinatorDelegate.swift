import UIKit
import WMFData

public protocol YearInReviewCoordinatorDelegate: AnyObject {
    func handleYearInReviewAction(_ action: YearInReviewCoordinatorAction)
}

public enum YearInReviewCoordinatorAction {
    case tappedIntroV3GetStartedWhileLoggedIn
    case tappedIntroV3GetStartedWhileLoggedOut
    case tappedIntroV3DoneWhileLoggedOut
    case donate(getSourceRect: () -> CGRect, slideLoggingID: String)
    case share(image: UIImage)
    case dismiss(hasSeenTwoSlides: Bool)
    case introLearnMore
    case learnMoreAttributedText(url: URL?, shouldShowDonateButton: Bool, slideLoggingID: String)
    case info
}

import UIKit
import WMFData

public protocol YearInReviewCoordinatorDelegate: AnyObject {
    func handleYearInReviewAction(_ action: YearInReviewCoordinatorAction)
}

public enum YearInReviewCoordinatorAction {
    case tappedIntroV3GetStartedWhileLoggedIn
    case tappedIntroV3GetStartedWhileLoggedOut
    case tappedIntroV3DoneWhileLoggedOut
    case donate(getSourceRect: () -> CGRect)
    case share(image: UIImage)
    case dismiss(hasSeenTwoSlides: Bool)
    case introLearnMore
    case learnMore(url: URL?, shouldShowDonateButton: Bool)
    case info(url: URL?)
}

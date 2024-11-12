import UIKit

public protocol YearInReviewCoordinatorDelegate: AnyObject {
    func handleYearInReviewAction(_ action: YearInReviewCoordinatorAction)
}

public enum YearInReviewCoordinatorAction {
    case donate(sourceRect: CGRect)
    case share(image: UIImage)
    case dismiss(isLastSlide: Bool)
    case introLearnMore
    case learnMore(url: URL, fromPersonalizedDonateSlide: Bool)
}

import UIKit

public protocol YearInReviewCoordinatorDelegate: AnyObject {
    func handleYearInReviewAction(_ action: YearInReviewCoordinatorAction)
}

public enum YearInReviewCoordinatorAction {
    case donate(sourceRect: CGRect, slideLoggingID: String, isLastSlide: Bool)
    case share(image: UIImage)
    case dismiss(isLastSlide: Bool)
}

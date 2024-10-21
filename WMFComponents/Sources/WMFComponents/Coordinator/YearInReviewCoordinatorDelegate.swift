import Foundation

public protocol YearInReviewCoordinatorDelegate: AnyObject {
    func handleYearInReviewAction(_ action: YearInReviewCoordinatorAction, sourceRect: CGRect)
}

public enum YearInReviewCoordinatorAction {
    case donate
}

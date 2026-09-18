import Foundation
import UIKit

public protocol WMFYearInReviewCoordinating: AnyObject {
    func handleYearInReviewAction(_ action: WMFYearInReviewAction)
}

public enum WMFYearInReviewAction {
    case close
    case learnMore(slideLoggingID: String)
    case shareFeedback(slideLoggingID: String)
    case share(slideID: String)
    case donate(getSourceRect: @MainActor () -> CGRect, slideLoggingID: String)
}

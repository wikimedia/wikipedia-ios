import Foundation
import UIKit

public protocol WMFYearInReviewCoordinating: AnyObject {
    func handleYearInReviewAction(_ action: WMFYearInReviewAction)
}

public enum WMFYearInReviewAction {
    case close
    /// Opens the project page.
    case learnMore(slideLoggingID: String)
    /// Opens the FAQ answer on how insights are calculated.
    case aboutInsights(slideLoggingID: String)
    case shareFeedback(slideLoggingID: String)
    case share(slideID: String)
    case donate(getSourceRect: @MainActor () -> CGRect, slideLoggingID: String)
}

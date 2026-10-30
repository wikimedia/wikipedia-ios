import Foundation
import UIKit

public protocol WMFYearInReviewCoordinating: AnyObject {
    func handleYearInReviewAction(_ action: WMFYearInReviewAction)
}

public enum WMFYearInReviewAction {
    case close
    /// Opens the project page.
    case learnMore(slideLoggingID: String)
    /// Opens the FAQ.
    case aboutInsights(slideLoggingID: String)
    case shareFeedback(slideLoggingID: String)
    case share(slideID: String)
    /// Shares the highlights image from the end screen.
    case shareHighlights
    case donate(getSourceRect: @MainActor () -> CGRect, slideLoggingID: String)
}

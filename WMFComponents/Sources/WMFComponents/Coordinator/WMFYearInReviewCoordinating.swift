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
    /// `getSourceRect` is the button frame in global coordinates, for the share sheet on iPad.
    case shareHighlights(getSourceRect: @MainActor () -> CGRect)
    case donate(getSourceRect: @MainActor () -> CGRect, slideLoggingID: String)
}

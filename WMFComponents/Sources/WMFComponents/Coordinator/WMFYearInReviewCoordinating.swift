import Foundation
import UIKit

public protocol WMFYearInReviewCoordinating: AnyObject {
    func handleYearInReviewAction(_ action: WMFYearInReviewAction)
}

public enum WMFYearInReviewAction {
    case close
    case showMoreMenu
    case share(slideID: String)
    case donate(getSourceRect: @MainActor () -> CGRect, slideLoggingID: String)
}

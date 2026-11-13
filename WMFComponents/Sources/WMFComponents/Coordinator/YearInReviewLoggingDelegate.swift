import Foundation

public protocol WMFYearInReviewLoggingDelegate: AnyObject {
    func logYearInReviewIntroDidTapLearnMore()
    func logYearInReviewSlideDidAppear(slideLoggingID: String)
    /// The pager settled on the end screen, which is not a slide.
    @MainActor func logYearInReviewEndDidAppear()
    func logYearInReviewDidTapDone(slideLoggingID: String)
    func logYearInReviewDidTapNext(slideLoggingID: String)
    func logYearInReviewDidTapDonate(slideLoggingID: String)
    func logYearInReviewDidTapShare(slideLoggingID: String)
    /// "Share highlights" on the end screen, which is not a slide.
    func logYearInReviewDidTapShareHighlights()
}

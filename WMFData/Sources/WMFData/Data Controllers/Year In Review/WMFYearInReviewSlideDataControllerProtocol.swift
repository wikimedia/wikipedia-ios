import Foundation
import CoreData

public protocol YearInReviewSlideDataControllerProtocol {
    /// A unique identifier for the slide (e.g., readCount, editCount).
    var id: String { get }

    /// The year this slide belongs to.
    var year: Int { get }

    /// Whether this slide has been evaluated.
    var isEvaluated: Bool { get set }

    /// Populate the slide’s data in the background context, using dependencies like saved data, page views, or edit stats.
    func populateSlideData(in context: NSManagedObjectContext) async throws

    /// Returns an instance of `CDYearInReviewSlide` (used for Core Data storage).
    func makeCDSlide(in context: NSManagedObjectContext) throws -> CDYearInReviewSlide

    /// Used to determine if the slide should be populated based on feature flags, user info, etc.
    static func shouldPopulate(from config: YearInReviewFeatureConfig, userInfo: YearInReviewUserInfo) -> Bool
    
    /// Used to create initial core data slide
    static func makeInitialCDSlide(for year: Int, in context: NSManagedObjectContext) throws -> CDYearInReviewSlide
}

import Foundation
import CoreData

public struct YearInReviewFeatureConfig {
    let isEnabled: Bool
    let slideConfig: SlideConfig
    let dataPopulationStartDateString: String?
    let dataPopulationEndDateString: String?
    let dataPopulationStartDate: Date?
    let dataPopulationEndDate: Date?
}


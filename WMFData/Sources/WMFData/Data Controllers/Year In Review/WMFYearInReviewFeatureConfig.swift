import Foundation
import CoreData

public struct YearInReviewFeatureConfig {
    let isEnabled: Bool
    let slideConfig: SlideConfig
    let dataPopulationStartDate: Date?
    let dataPopulationEndDate: Date?
}


import Foundation

public class WMFYearInReviewSlide: Identifiable {
    public let year: Int
    public let id: WMFYearInReviewPersonalizedSlideID
    public var data: Data?

    init(year: Int, id: WMFYearInReviewPersonalizedSlideID, data: Data? = nil) {
        self.year = year
        self.id = id
        self.data = data
    }
}

public enum WMFYearInReviewPersonalizedSlideID: String, Comparable {
    case readCount
    case editCount
    case donateCount
    case saveCount
    case mostReadDay
    case viewCount

    public static func < (lhs: WMFYearInReviewPersonalizedSlideID, rhs: WMFYearInReviewPersonalizedSlideID) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
    func dataController() -> YearInReviewSlideDataControllerProtocol.Type {
        switch self {
        case .readCount:
            return YearInReviewReadCountSlideDataController.self
        case .editCount:
            return YearInReviewEditCountSlideDataController.self
        case .donateCount:
            return YearInReviewDonateCountSlideDataController.self
        case .saveCount:
            return YearInReviewSaveCountSlideDataController.self
        case .mostReadDay:
            return YearInReviewMostReadDaySlideDataController.self
        case .viewCount:
            return YearInReviewViewCountSlideDataController.self
        }
    }
}

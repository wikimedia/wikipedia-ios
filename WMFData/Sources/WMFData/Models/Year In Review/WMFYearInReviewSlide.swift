import Foundation

public final class WMFYearInReviewSlide: Identifiable, @unchecked Sendable {
    public let year: Int
    public let id: WMFYearInReviewPersonalizedSlideID
    
    // Private serial queue to safely access `data`
    private var _data: Data?
    private let queue = DispatchQueue(label: "WMFYearInReviewSlide.data.queue")

    public var data: Data? {
        get { queue.sync { _data } }
        set { queue.sync { _data = newValue } }
    }

    init(year: Int, id: WMFYearInReviewPersonalizedSlideID, data: Data? = nil) {
        self.year = year
        self.id = id
        self._data = data
    }
}

public enum WMFYearInReviewPersonalizedSlideID: String, Comparable, Sendable {
    case readCount
    case editCount
    case donateCount
    case saveCount
    case mostReadDate
    case viewCount
    case topArticles
    case mostReadCategories
    case location

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
        case .mostReadDate:
            return YearInReviewMostReadDateSlideDataController.self
        case .viewCount:
            return YearInReviewViewCountSlideDataController.self
        case .topArticles:
            return YearInReviewTopReadArticleSlideDataController.self
        case .mostReadCategories:
            return YearInReviewMostReadCategoriesSlideDataController.self
        case .location:
            return YearInReviewLocationSlideDataController.self
        }
    }
}

import Foundation
import CoreData

// MARK: - Read Count Slide
public final class YearInReviewReadCountSlide: YearInReviewSlideProtocol {

    public let id = WMFYearInReviewPersonalizedSlideID.readCount.rawValue
    public let year: Int
    public var isEvaluated: Bool
    private var readCount: Int?

    private let legacyPageViews: [WMFLegacyPageView]

    public init(year: Int, legacyPageViews: [WMFLegacyPageView], isEvaluated: Bool = false) {
        self.year = year
        self.legacyPageViews = legacyPageViews
        self.isEvaluated = isEvaluated
    }

    public func populateSlideData(in context: NSManagedObjectContext) async throws {
        readCount = legacyPageViews.count
        isEvaluated = true
    }

    public func makeCDSlide(in context: NSManagedObjectContext) throws -> CDYearInReviewSlide {
        let slide = CDYearInReviewSlide(context: context)
        slide.id = id
        slide.year = Int32(year)

        if let readCount {
            let encoder = JSONEncoder()
            slide.data = try encoder.encode(readCount)
        }

        return slide
    }

    public static func shouldPopulate(from config: YearInReviewFeatureConfig, userInfo: YearInReviewUserInfo) -> Bool {
        return config.isEnabled && config.slideConfig.readCountIsEnabled
    }
    
    public static func makeInitialCDSlide(for year: Int, in context: NSManagedObjectContext) throws -> CDYearInReviewSlide {
        let slide = CDYearInReviewSlide(context: context)
        slide.id = WMFYearInReviewPersonalizedSlideID.readCount.rawValue
        slide.year = Int32(year)
        slide.data = nil
        return slide
    }
}

// MARK: - Save Count Slide

public final class YearInReviewSaveCountSlide: YearInReviewSlideProtocol {

    public let id = WMFYearInReviewPersonalizedSlideID.saveCount.rawValue
    public let year: Int
    public var isEvaluated: Bool
    private var savedData: SavedArticleSlideData?

    public init(year: Int, savedData: SavedArticleSlideData?, isEvaluated: Bool = false) {
        self.year = year
        self.savedData = savedData
        self.isEvaluated = isEvaluated
    }

    public func populateSlideData(in context: NSManagedObjectContext) async throws {
        guard savedData != nil else { return }
        isEvaluated = true
    }

    public func makeCDSlide(in context: NSManagedObjectContext) throws -> CDYearInReviewSlide {
        let slide = CDYearInReviewSlide(context: context)
        slide.id = id
        slide.year = Int32(year)

        if let savedData {
            slide.data = try JSONEncoder().encode(savedData)
        }

        return slide
    }

    public static func shouldPopulate(from config: YearInReviewFeatureConfig, userInfo: YearInReviewUserInfo) -> Bool {
        return config.isEnabled && config.slideConfig.saveCountIsEnabled && userInfo.savedArticlesData != nil
    }
    
    public static func makeInitialCDSlide(for year: Int, in context: NSManagedObjectContext) throws -> CDYearInReviewSlide {
        let slide = CDYearInReviewSlide(context: context)
        slide.id = WMFYearInReviewPersonalizedSlideID.saveCount.rawValue
        slide.year = Int32(year)
        slide.data = nil
        return slide
    }
}

// MARK: - Edit count slide

public final class YearInReviewEditCountSlide: YearInReviewSlideProtocol {

    public let id = WMFYearInReviewPersonalizedSlideID.editCount.rawValue
    public let year: Int
    public var isEvaluated: Bool
    private var editCount: Int?

    private let username: String?
    private let project: WMFProject?
    private let fetchEditCount: (String, WMFProject?) async throws -> Int

    public init(year: Int, username: String?, project: WMFProject?, isEvaluated: Bool = false,
                fetchEditCount: @escaping (String, WMFProject?) async throws -> Int) {
        self.year = year
        self.username = username
        self.project = project
        self.isEvaluated = isEvaluated
        self.fetchEditCount = fetchEditCount
    }

    public func populateSlideData(in context: NSManagedObjectContext) async throws {
        guard let username, let project else { return }
        editCount = try await fetchEditCount(username, project)
        isEvaluated = true
    }

    public func makeCDSlide(in context: NSManagedObjectContext) throws -> CDYearInReviewSlide {
        let slide = CDYearInReviewSlide(context: context)
        slide.id = id
        slide.year = Int32(year)

        if let editCount {
            slide.data = try JSONEncoder().encode(editCount)
        }

        return slide
    }

    public static func shouldPopulate(from config: YearInReviewFeatureConfig, userInfo: YearInReviewUserInfo) -> Bool {
        return config.isEnabled && config.slideConfig.editCountIsEnabled && userInfo.username != nil
    }
    
    public static func makeInitialCDSlide(for year: Int, in context: NSManagedObjectContext) throws -> CDYearInReviewSlide {
        let slide = CDYearInReviewSlide(context: context)
        slide.id = WMFYearInReviewPersonalizedSlideID.editCount.rawValue
        slide.year = Int32(year)
        slide.data = nil
        return slide
    }
}

// MARK: - Donate Slide

public final class YearInReviewDonateCountSlide: YearInReviewSlideProtocol {
    public let id = WMFYearInReviewPersonalizedSlideID.donateCount.rawValue
    public let year: Int
    public var isEvaluated: Bool
    private var donateCount: Int?

    private let donationFetcher: (Date, Date) -> Int?
    private let dateRange: (Date, Date)?

    public init(year: Int, dateRange: (Date, Date)?, isEvaluated: Bool = false,
                donationFetcher: @escaping (Date, Date) -> Int?) {
        self.year = year
        self.dateRange = dateRange
        self.donationFetcher = donationFetcher
        self.isEvaluated = isEvaluated
    }

    public func populateSlideData(in context: NSManagedObjectContext) async throws {
        guard let (start, end) = dateRange else { return }
        donateCount = donationFetcher(start, end)
        isEvaluated = true
    }

    public func makeCDSlide(in context: NSManagedObjectContext) throws -> CDYearInReviewSlide {
        let slide = CDYearInReviewSlide(context: context)
        slide.id = id
        slide.year = Int32(year)
        slide.data = try donateCount.map { try JSONEncoder().encode($0) }
        return slide
    }

    public static func shouldPopulate(from config: YearInReviewFeatureConfig, userInfo: YearInReviewUserInfo) -> Bool {
        config.isEnabled && config.slideConfig.donateCountIsEnabled
    }
    
    public static func makeInitialCDSlide(for year: Int, in context: NSManagedObjectContext) throws -> CDYearInReviewSlide {
        let slide = CDYearInReviewSlide(context: context)
        slide.id = WMFYearInReviewPersonalizedSlideID.donateCount.rawValue
        slide.year = Int32(year)
        slide.data = nil
        return slide
    }
}

// MARK: - Most read day slide

public final class YearInReviewMostReadDaySlide: YearInReviewSlideProtocol {
    public let id = WMFYearInReviewPersonalizedSlideID.mostReadDay.rawValue
    public let year: Int
    public var isEvaluated: Bool
    private var mostReadDay: WMFPageViewDay?

    private let legacyPageViews: [WMFLegacyPageView]

    public init(year: Int, legacyPageViews: [WMFLegacyPageView], isEvaluated: Bool = false) {
        self.year = year
        self.legacyPageViews = legacyPageViews
        self.isEvaluated = isEvaluated
    }

    public func populateSlideData(in context: NSManagedObjectContext) async throws {
        let dayCounts = legacyPageViews.reduce(into: [Int: Int]()) { dict, view in
            let day = Calendar.current.component(.weekday, from: view.viewedDate)
            dict[day, default: 0] += 1
        }

        if let (day, count) = dayCounts.max(by: { $0.value < $1.value }) {
            mostReadDay = WMFPageViewDay(day: day, viewCount: count)
            isEvaluated = true
        }
    }

    public func makeCDSlide(in context: NSManagedObjectContext) throws -> CDYearInReviewSlide {
        let slide = CDYearInReviewSlide(context: context)
        slide.id = id
        slide.year = Int32(year)
        slide.data = try mostReadDay.map { try JSONEncoder().encode($0) }
        return slide
    }

    public static func shouldPopulate(from config: YearInReviewFeatureConfig, userInfo: YearInReviewUserInfo) -> Bool {
        config.isEnabled && config.slideConfig.mostReadDayIsEnabled
    }
    
    public static func makeInitialCDSlide(for year: Int, in context: NSManagedObjectContext) throws -> CDYearInReviewSlide {
        let slide = CDYearInReviewSlide(context: context)
        slide.id = WMFYearInReviewPersonalizedSlideID.mostReadDay.rawValue
        slide.year = Int32(year)
        slide.data = nil
        return slide
    }
}

// MARK: - View count

public final class YearInReviewViewCountSlide: YearInReviewSlideProtocol {
    public let id = WMFYearInReviewPersonalizedSlideID.viewCount.rawValue
    public let year: Int
    public var isEvaluated: Bool
    private var viewCount: Int?

    private let userID: String?
    private let languageCode: String?
    private let project: WMFProject?
    private let fetchViews: (WMFProject?, String, String) async throws -> Int

    public init(year: Int, userID: String?, languageCode: String?, project: WMFProject?,
                fetchViews: @escaping (WMFProject?, String, String) async throws -> Int, isEvaluated: Bool = false) {
        self.year = year
        self.userID = userID
        self.languageCode = languageCode
        self.project = project
        self.fetchViews = fetchViews
        self.isEvaluated = isEvaluated
    }

    public func populateSlideData(in context: NSManagedObjectContext) async throws {
        guard let userID, let languageCode else { return }
        viewCount = try await fetchViews(project, userID, languageCode)
        isEvaluated = true
    }

    public func makeCDSlide(in context: NSManagedObjectContext) throws -> CDYearInReviewSlide {
        let slide = CDYearInReviewSlide(context: context)
        slide.id = id
        slide.year = Int32(year)
        slide.data = try viewCount.map { try JSONEncoder().encode($0) }
        return slide
    }

    public static func shouldPopulate(from config: YearInReviewFeatureConfig, userInfo: YearInReviewUserInfo) -> Bool {
        config.isEnabled && config.slideConfig.viewCountIsEnabled && userInfo.userID != nil
    }
    
    public static func makeInitialCDSlide(for year: Int, in context: NSManagedObjectContext) throws -> CDYearInReviewSlide {
        let slide = CDYearInReviewSlide(context: context)
        slide.id = WMFYearInReviewPersonalizedSlideID.viewCount.rawValue
        slide.year = Int32(year)
        slide.data = nil
        return slide
    }
}


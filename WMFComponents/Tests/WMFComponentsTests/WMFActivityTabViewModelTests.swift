import XCTest
@testable import WMFComponents
@testable import WMFData

@MainActor
final class WMFActivityTabViewModelTests: XCTestCase {
    
    private var mockDataController: MockActivityTabDataController!
    private var viewModel: WMFActivityTabViewModel!
    
    override func setUp() {
        super.setUp()
        mockDataController = MockActivityTabDataController()
        
        let strings = WMFActivityTabViewModel.LocalizedStrings.demoStrings()
        
        viewModel = WMFActivityTabViewModel(
            localizedStrings: strings,
            dataController: mockDataController,
            hasSeenActivityTab: {},
            isLoggedIn: true
        )
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testInitialModelDefaults() {
        let model = viewModel.model
        XCTAssertEqual(model.username, "")
        XCTAssertEqual(model.hoursRead, 0)
        XCTAssertEqual(model.minutesRead, 0)
        XCTAssertEqual(model.totalArticlesRead, 0)
        XCTAssertEqual(model.weeklyReads, [])
        XCTAssertEqual(model.topCategories, [])
        XCTAssertEqual(model.articlesSavedAmount, 0)
        XCTAssertTrue(model.articlesSavedImages.isEmpty)
        XCTAssertTrue(model.dateTimeLastRead.isEmpty)
        XCTAssertTrue(model.dateTimeLastSaved.isEmpty)
    }
    
    func testUpdateUsernameSetsModelAndReadingText() {
        let username = "Alice"
        viewModel.updateUsername(username: username)
        
        XCTAssertEqual(viewModel.model.username, username)
        XCTAssertEqual(viewModel.model.usernamesReading, "Alice")
    }
    
    func testUpdateUsernameEmptyUsesNoUsernameText() {
        viewModel.updateUsername(username: "")
        
        XCTAssertEqual(viewModel.model.username, "")
        XCTAssertEqual(viewModel.model.usernamesReading, "")
    }
    
    func testUpdateIsLoggedInChangesPublishedValue() {
        XCTAssertTrue(viewModel.isLoggedIn)
        viewModel.updateIsLoggedIn(isLoggedIn: false)
        XCTAssertFalse(viewModel.isLoggedIn)
    }
    
    func testFetchDataPopulatesModel() async {
        mockDataController.hours = 5
        mockDataController.minutes = 45
        mockDataController.totalArticles = 123
        mockDataController.mostRecentDate = Date(timeIntervalSince1970: 1_700_000_000)
        mockDataController.weeklyReads = [5, 10, 8, 12, 6, 9, 11]
        mockDataController.categories = ["Science", "History", "Technology"]

        viewModel.fetchData()

        let timeout = Date().addingTimeInterval(2) // 2 seconds timeout
        while viewModel.model.hoursRead == 0 && Date() < timeout {
            await Task.yield()
        }

        let model = viewModel.model
        XCTAssertEqual(model.hoursRead, 5)
        XCTAssertEqual(model.minutesRead, 45)
        XCTAssertEqual(model.totalArticlesRead, 123)
        XCTAssertEqual(model.weeklyReads, [5, 10, 8, 12, 6, 9, 11])
        XCTAssertEqual(model.topCategories, ["Science", "History", "Technology"])
        XCTAssertFalse(model.dateTimeLastRead.isEmpty)
    }
}

// MARK: - Localized Strings Demo Extension

private extension WMFActivityTabViewModel.LocalizedStrings {
    static func demoStrings() -> WMFActivityTabViewModel.LocalizedStrings {
        return WMFActivityTabViewModel.LocalizedStrings(
            userNamesReading: { "\($0)" },
            noUsernameReading: "",
            totalHoursMinutesRead: { hours, minutes in "\(hours)h \(minutes)m read" },
            onWikipediaiOS: "on Wikipedia iOS",
            timeSpentReading: "Time spent reading",
            totalArticlesRead: "Articles read",
            week: "Week",
            articlesRead: "Articles read",
            topCategories: "Top categories",
            articlesSavedTitle: "Saved articles",
            remaining: { "\($0) remaining" },
            loggedOutTitle: "Log in to see your activity",
            loggedOutSubtitle: "Track your reading history and saved articles",
            loggedOutPrimaryCTA: "Log in",
            loggedOutSecondaryCTA: "Learn more"
        )
    }
}

// MARK: - Mocks

final class MockSavedArticlesDelegate {
    struct MockSavedData {
        let savedArticlesCount: Int
        let dateLastSaved: Date
        let articleUrlStrings: [String]
    }
    
    var mockData: MockSavedData?
    
    func getSavedArticleModuleData(from: Date, to: Date) async -> SavedArticleModuleData? {
        guard let mockData else { return nil }
        return SavedArticleModuleData(
            savedArticlesCount: mockData.savedArticlesCount,
            articleUrlStrings: mockData.articleUrlStrings,
            dateLastSaved: mockData.dateLastSaved
        )
    }
}

final class MockActivityTabDataController: WMFActivityTabDataControlling {
    var hours: Int = 0
    var minutes: Int = 0
    var totalArticles: Int = 0
    var mostRecentDate: Date = Date()
    var weeklyReads: [Int] = []
    var categories: [String] = []
    
    var shouldShowActivityTab: Bool = false
    var hasSeenActivityTab: Bool = false
    
    var didCallGetActivityAssignment = false
    
    func getTimeReadPast7Days() async throws -> (Int, Int)? {
        return (hours, minutes)
    }
    
    func getArticlesRead() async throws -> Int {
        return totalArticles
    }
    
    func getWeeklyReadsThisMonth() async throws -> [Int] {
        return weeklyReads
    }
    
    func getMostRecentReadDateTime() async throws -> Date? {
        return mostRecentDate
    }
    
    func getTopCategories() async throws -> [String]? {
        return categories
    }
    
    func getActivityAssignment() -> Int {
        didCallGetActivityAssignment = true
        return shouldShowActivityTab ? 1 : 0
    }
}

import XCTest

final class UITest: XCTestCase {
    
    override func setUp() {
        let app = XCUIApplication(bundleIdentifier: "org.wikimedia.wikipedia")
        app.launch()
    }
    
    func testSettingsButtonAfterForwardAndBackward() {
        FeedScreen()
            .checkSettingsButtonIsHittable()
            .tapSettingsButton()
        SettingsScreen()
            .checkTitleIsHittable()
            .tapCloseButton()
        FeedScreen()
            .checkSettingsButtonIsHittable()
    }
    
    func testTapBarElements() {
        TapBar()
            .tapSearch()
            .checkSearchSelection(isSelectedElement: true)
            .checkFeedSelection(isSelectedElement: false)
            .tapFeed()
            .checkSearchSelection(isSelectedElement: false)
            .checkFeedSelection(isSelectedElement: true)
    }
    
    func testModelOfBusinessSearch() {
        FeedScreen()
            .swipeToContinue()
            .tapReadingContinue()
        ModelOfBusinessSearchScreen()
            .tapContent()
            .tapModelOfBusiness()
            .checkModelOfBusinessPage()
    }
    
    func testCleanHistory() {
        TapBar()
            .tapHistory()
        HistoryScreen()
            .checkHistoryWithElements()
            .tapClean()
            .checkHistoryEmpty()
    }
    
    func testAboutApplicationFilled() {
        FeedScreen()
            .tapSettingsButton()
        AboutApplicationScreen()
            .tapAbout()
            .checkAuthors()
            .checkTranslators()
            .checkLicense()
    }
    
    func testForwardToBrowser() {
        FeedScreen()
            .tapSettingsButton()
        SettingsScreen()
            .tapSupportWiki()
        BrowserScreen()
            .checkBrowser()
    }
    
    func testTopReadButton() {
        FeedScreen()
            .tapTopRead()
        TopReadScreen()
            .checkTopReadScreen()
    }
    
    func testLocationButton() {
        TapBar()
            .tapPlacesButton()
        WatchPlacesScreen()
            .tapLocationButton()
            .checkSwitchOnLocationButton()
    }
    
    func testSeatchingScreen() {
        TapBar()
            .tapSearch()
        SearchingScreen()
            .typeSearchField("Тинькофф банк")
            .tapFirstItemInList("Тинькофф банк")
            .checkPageExist("Тинькофф банк")
    }
}

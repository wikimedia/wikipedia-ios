import XCTest

/*
 
RECORDS APP SCREENSHOTS FOR VARIOUS DEVICES AND LANGS:
 
- details: https://docs.fastlane.tools/actions/snapshot/
- run the `bundle exec fastlane snapshot` command to kick off the screenshot taking test below
(when debugging `wmf_localizedString:key:` below sometimes I needed to re-run this command before things behaved as expected, probably due to how `SnapshotHelper.swift` interacts with simulators & builds)
- see `/fastlane/snapfile` to configure (langs, simulators, other parameters, etc)


STEPS FOR CAPTURING NEW SCREENSHOTS:
 
- select the "WikipediaUITests" scheme
- open `/fastlane/snapfile` and *temporarily* comment out every lang and simulator but one - ie `EN` and `iPhone 5s`, for example
- run the `bundle exec fastlane snapshot` command once
- i think this lets `SnapshotHelper.swift` configure our build in that simulator? anyway breakpoints set in the `testRecordAppScreenshots()` test below should work as expected after running this once.
- then when you select the `iPhone 5s` simulator (in Xcode) and hit the play button on the `testRecordAppScreenshots()` test below it will behave as expected (ie not fail in unexplainable ways because it's configured for non-EN)
- once the `testRecordAppScreenshots()` test is navigating to the parts of the app you want to record pics, add `snapshot("SomeRelevantString")` where you want pics to be taken (note: no pic will actually be recorded when you're manually running the tests here - that only happens when you run `bundle exec fastlane snapshot`)
- after everthing is working don't forget to turn off breakpoints
- then run `bundle exec fastlane snapshot` - this will record pics for the one lang and sim you chose so you can do a quick proof and ensure all the images are being saved
- re-open `/fastlane/snapfile` and undo the comment you added in the 2nd step above (so snapshots for all sims and langs are recorded)
- run `bundle exec fastlane snapshot` to take snapshots for ALL langs and sims (this can take a while)


TIPS:
 
- setting a breakpoint in the `testRecordAppScreenshots()` test, running it, and using `print(XCUIApplication().debugDescription)` in the console when the breakpoint hits is handy for seeing what buttons/elements we can interact with or tap on the current screen. Find the button with the label string you are looking for (in the tree printed by `print(XCUIApplication().debugDescription)`) then find the key for that label's localized string and use it (this is what enables these tests to work in non-EN langs).
- the Xcode Accessiblity Inspector ("Xcode > Open Developer Tool > Accessibility Inspector") is also VERY useful for seeing what accessibility label strings are associated with text-less image buttons.
- `sleep(n)` is also handy for pausing when debugging (this uitest target sleeps - the app doesn't)
- uncheck "main thread checker" https://github.com/fastlane/fastlane/issues/10381#issuecomment-332183767 and https://forums.developer.apple.com/thread/86476
- it appears to not work correctly if you try to have more than one test kick off screenshot recording. weird freezes, etc. so below we just use the single test method: `testRecordAppScreenshots()` for now
- set a breakpoint on a call to `sleep(n)` in location of interest, then `print(XCUIApplication().debugDescription)` to get tree of what's onscreen so you can find button string to use to search for localization key for that string so you can programatically "push" that button
- you can use control-option-command-U to re-run last test you ran!
- remember that when this gets run by fastlane the app is a clean install every time (so we start from the first welcome screen) but when tweaking tests you may have left off after the welcome screens (so you can just temporarily comment out the welcome screen lines below when adding new screenshots). just be sure that when you're done adding new screenshots you test with clean install and that all the steps progress normally - you should be able to watch it progress through the first welcome screen all the way to the last item below - that way you'll know when fastlane does the same thing from a clean install that everything will go smoothly.

*/

class WikipediaUITests: XCTestCase {
    
    let app = XCUIApplication()
    var snapshotIndex = 0

    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        
        snapshotIndex = 0
        
        // uncomment one of these as needed when testing (useful when adding new screenshots to ensure `tapButton` works with non-EN)
        /*
         app.launchArguments = [
             "-AppleLanguages",
             "(de)",
             "-AppleLocale",
             "de_DE"
         ]

         app.launchArguments = [
             "-AppleLanguages",
             "(zh)",
             "-AppleLocale",
             "zh_Hans"
         ]

        app.launchArguments = [
            "-AppleLanguages",
            "(ja)",
            "-AppleLocale",
            "ja_JA"
        ]
        */
        
        
        setupSnapshot(app)
        
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        app.launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    // Prepends an auto-incremented numeric prefix to screenshot names so they appear on the index html page in the order they were captured.
    func wmf_snapshot(_ name: String, timeWaitingForIdle timeout: TimeInterval = 20) {
        snapshot("\(String(format: "%04d", snapshotIndex))-\(name)", timeWaitingForIdle: timeout)
        snapshotIndex = snapshotIndex + 1
    }
    
    // This UI test is used as a harness to navigate to various parts of the app and record screenshots. Fastlane snapshots don't seem to play nice with multiple tests taking snapshots, so we have all of them in this single test.
    func testRecordAppScreenshots() {

        
        // WECOME
        wmf_snapshot("WelcomeScreen1")

        app.wmf_tapButton(key: "welcome-intro-free-encyclopedia-more")
        wmf_snapshot("WelcomeScreen2")

        app.wmf_tapButton(key: "welcome-explore-tell-me-more-done-button")
        wmf_snapshot("WelcomeScreen3")

        app.wmf_tapButton(key: "button-next")
        wmf_snapshot("WelcomeScreen4")

        app.wmf_tapButton(key: "button-next")
        wmf_snapshot("WelcomeScreen5")

        app.wmf_tapButton(key: "welcome-languages-add-or-edit-button")
        wmf_snapshot("WelcomeScreen6")

        app.wmf_tapButton(key: "close-button-accessibility-label")

        app.wmf_tapButton(key: "button-next")
        wmf_snapshot("WelcomeScreen7")
        app.wmf_tapButton(key: "welcome-explore-continue-button")

        
        // Useful if you temporarily comment out the welcome screens above.
        // app.wmf_tapButton(key: "button-skip")

        
        // EXPLORE
        app.wmf_tapButton(key: "home-title")
        wmf_snapshot("ExploreScreen1")

        app.wmf_scrollToOtherElementStartingWith(key: "explore-potd-heading", success: { element in
            wmf_snapshot("ExploreScreenPicOfTheDay")

            element.tap()
            sleep(8)
            wmf_snapshot("GalleryScreen")
            app.wmf_tapUnlocalizedCloseButton()
        })

        app.wmf_scrollToOtherElementStartingWith(key: "explore-featured-article-heading", success: { element in
            wmf_snapshot("ExploreScreenFeaturedArticle")
        })

        app.wmf_scrollToOtherElementStartingWith(key: "explore-most-read-heading", success: { element in
            wmf_snapshot("ExploreScreenMostRead")

            element.tap()
            sleep(4)
            wmf_snapshot("MostReadDetail")
            app.wmf_tapButton(key: "back")
        })

        app.wmf_scrollToOtherElementStartingWith(key: "on-this-day-title", success: { element in
            wmf_snapshot("ExploreScreenOnThisDay")

            element.tap()
            sleep(4)
            wmf_snapshot("OnThisDayDetail")
            app.wmf_tapButton(key: "back")
        })

        app.wmf_scrollToOtherElementStartingWith(key: "explore-nearby-placeholder-heading", success: { element in
            wmf_snapshot("ExploreScreenNearbyPlaces")
        })

        app.wmf_scrollToOtherElementStartingWith(key: "explore-random-article-heading", success: { element in
            wmf_snapshot("ExploreScreenRandom")
            
            element.tap()
            sleep(8)
            wmf_snapshot("RandomDetail")
            app.wmf_tapButton(key: "back")
        })

        app.wmf_scrollToOtherElementStartingWith(key: "explore-main-page-heading", success: { element in
            wmf_snapshot("ExploreScreenMainPage")

            element.tap()
            sleep(8)
            wmf_snapshot("MainPageDetail")
            app.wmf_tapButton(key: "back")
        })

        app.wmf_scrollToOtherElementStartingWith(key: "in-the-news-title", success: { element in
            wmf_snapshot("ExploreScreenInTheNews")
            
            element.tap()
            sleep(4)
            wmf_snapshot("InTheNewsDetail")
            app.wmf_tapButton(key: "back")
        })
    
        
        // SEARCH
        app.wmf_scrollToTop()
        app.wmf_tapSearchField(key: "search-field-placeholder-text")
        wmf_snapshot("SearchScreen1")
        app.wmf_searchField(key: "search-field-placeholder-text").typeText("a")
        wmf_snapshot("SearchScreen2")
        
        
        // ARTICLE
        app.wmf_tapFirstCollectionViewCell()
        sleep(8)
        wmf_snapshot("ArticleScreen1")
        sleep(8) // give popover time to disappear (this uitest target sleeps - the app doesn't)

        // TOC and ARTICLE FOOTERS
        if UIDevice.current.userInterfaceIdiom != .pad {
            // TOC
            app.wmf_tapButton(key: "table-of-contents-button-label")
            wmf_snapshot("ArticleScreenTOC")
            
            // `About this article` footer
            app.wmf_tapStaticText(key: "article-about-title")
            wmf_snapshot("ArticleScreenFooterAboutThisArticle")

            // `Read more` footer
            app.wmf_tapButton(key: "table-of-contents-button-label")
            app.wmf_tapStaticText(key: "article-read-more-title")
            wmf_snapshot("ArticleScreenFooterReadMore")
        } else {
            // Article footer (both the `About this article` and `Read more` footers are visible on larger iPad screens so no need to do separate screenshot for `Read more`)
            app.wmf_tapStaticText(key: "article-about-title")
            wmf_snapshot("ArticleScreenFooter")
        }
        
        
        // Article theme panel
        app.wmf_tapButton(key: "article-toolbar-reading-themes-controls-toolbar-item")
        wmf_snapshot("ArticleScreenThemesLight")
        
        app.wmf_tapButton(key: "reading-themes-controls-accessibility-sepia-theme-button")
        wmf_snapshot("ArticleScreenThemesSepia")

        app.wmf_tapButton(key: "reading-themes-controls-accessibility-dark-theme-button")
        wmf_snapshot("ArticleScreenThemesDark")

        app.wmf_tapButton(key: "reading-themes-controls-accessibility-black-theme-button")
        wmf_snapshot("ArticleScreenThemesBlack")

        app.wmf_tapButton(key: "reading-themes-controls-accessibility-light-theme-button")

        sleep(8) // give popover time to disappear (this uitest target sleeps - the app doesn't)

        
        // Article find in page
        app.wmf_tapButton(key: "find-in-page-button-label")
        wmf_snapshot("ArticleScreenFindInPage1")
        app.textFields.firstMatch.typeText("a")
        wmf_snapshot("ArticleScreenFindInPage2")

        app.wmf_tapUnlocalizedCloseButton()
        
        app.wmf_tapButton(key: "home-button-explore-accessibility-label")

        
        // SETTINGS
        app.wmf_tapButton(key: "settings-title")
        wmf_snapshot("SettingsScreen1")

        
        // Login
        app.wmf_tapStaticText(key: "main-menu-account-login")
        wmf_snapshot("LoginScreen1")

        
        // Create account
        app.wmf_tapStaticTextStartingWith(key: "login-no-account")
        wmf_snapshot("CreateAccountScreen1")
        app.wmf_tapUnlocalizedCloseButton()

        
        // Forgot password
        app.wmf_tapStaticText(key: "main-menu-account-login")
        app.wmf_tapStaticText(key: "login-forgot-password")
        wmf_snapshot("ForgotPasswordScreen1")
        app.wmf_tapUnlocalizedCloseButton()

        
        // My languages
        app.wmf_tapStaticText(key: "settings-my-languages")
        wmf_snapshot("MyLanguagesScreen1")
        app.wmf_tapButton(key: "close-button-accessibility-label")

        
        // Notifications
        app.wmf_tapStaticText(key: "settings-notifications")
        wmf_snapshot("NotificationsScreen1")
        app.wmf_tapButton(key: "settings-title")

        
        // Reading preferences
        app.wmf_tapStaticText(key: "settings-appearance")
        wmf_snapshot("AppearanceScreen1")
        app.wmf_tapButton(key: "settings-title")

        
        // Article storage and syncing
        app.wmf_tapStaticText(key: "settings-storage-and-syncing-title")
        wmf_snapshot("StorageAndSyncingScreen1")
        app.wmf_tapButton(key: "settings-title")

        
        // Clear cached data
        app.wmf_tapStaticText(key: "settings-clear-cache")
        wmf_snapshot("ClearCacheScreen1")

        
        // Help and feedback
        app.wmf_tapStaticText(key: "settings-help-and-feedback")
        sleep(8)
        wmf_snapshot("HelpAndFeedbackScreen1")
        sleep(8) // give tooltip time to disappear (this uitest target sleeps - the app doesn't)
        app.wmf_tapButton(key: "settings-title")

        
        // About the app
        app.wmf_tapStaticText(key: "main-menu-about")
        sleep(8)
        wmf_snapshot("AboutTheAppScreen1")
        app.wmf_tapButton(key: "settings-title")
        app.wmf_tapButton(key: "close-button-accessibility-label")

        
        // SAVED
        app.wmf_tapButton(key: "saved-title")
        wmf_snapshot("SavedScreen1")

        
        // HISTORY
        app.wmf_tapButton(key: "history-title")
        wmf_snapshot("HistoryScreen1")

        
        // PLACES
        app.wmf_tapButton(key: "places-title")
        wmf_snapshot("PlacesScreen1")
    }
}

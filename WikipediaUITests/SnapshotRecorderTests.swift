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
- the Xcode Accessibility Inspector ("Xcode > Open Developer Tool > Accessibility Inspector") is also VERY useful for seeing what accessibility label strings are associated with text-less image buttons.
- `sleep(n)` is also handy for pausing when debugging (this uitest target sleeps - the app doesn't)
- uncheck "main thread checker" https://github.com/fastlane/fastlane/issues/10381#issuecomment-332183767 and https://forums.developer.apple.com/thread/86476
- it appears to not work correctly if you try to have more than one test kick off screenshot recording. weird freezes, etc. so below we just use the single test method: `testRecordAppScreenshots()` for now
- set a breakpoint on a call to `sleep(n)` in location of interest, then `print(XCUIApplication().debugDescription)` to get tree of what's onscreen so you can find button string to use to search for localization key for that string so you can programatically "push" that button
- you can use control-option-command-U to re-run last test you ran!
- remember that when this gets run by fastlane the app is a clean install every time (so we start from the first welcome screen) but when tweaking tests you may have left off after the welcome screens (so you can just temporarily comment out the welcome screen lines below when adding new screenshots). just be sure that when you're done adding new screenshots you test with clean install and that all the steps progress normally - you should be able to watch it progress through the first welcome screen all the way to the last item below - that way you'll know when fastlane does the same thing from a clean install that everything will go smoothly.
- when debugging it can be helpful to watch the screenshots appear in this temp dir: `~/Library/Caches/tools.fastlane/screenshots/`
 
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
    func wmf_snapshot(_ name: String, timeWaitingForIdle timeout: TimeInterval = 45) {
        sleep(2)
        snapshot("\(String(format: "%04d", snapshotIndex))-\(name)", timeWaitingForIdle: timeout)
        snapshotIndex = snapshotIndex + 1
        sleep(2)
    }
    
    // This UI test is used as a harness to navigate to various parts of the app and record screenshots. Fastlane snapshots don't seem to play nice with multiple tests taking snapshots, so we have all of them in this single test.
    func testRecordAppScreenshots() {


        // WECOME
        wmf_snapshot("WelcomeScreen1")

        _ = app.wmf_tapFirstButton(withTranslationIn: ["welcome-intro-free-encyclopedia-more"])
        wmf_snapshot("WelcomeScreen2")

        _ = app.wmf_tapFirstButton(withTranslationIn: ["welcome-explore-tell-me-more-done-button"])
        wmf_snapshot("WelcomeScreen3")

        _ = app.wmf_tapFirstButton(withTranslationIn: ["button-next"])
        wmf_snapshot("WelcomeScreen4")

        _ = app.wmf_tapFirstButton(withTranslationIn: ["button-next"])
        wmf_snapshot("WelcomeScreen5")

        _ = app.wmf_tapFirstButton(withTranslationIn: ["welcome-languages-add-or-edit-button"])
        wmf_snapshot("WelcomeScreen6")

        _ = app.wmf_tapFirstCloseButton()

        _ = app.wmf_tapFirstButton(withTranslationIn: ["button-next"])
        wmf_snapshot("WelcomeScreen7")
        
        _ = app.wmf_tapFirstSwitch(withTranslationIn: ["preference-title-eventlogging-opt-in"])
        wmf_snapshot("WelcomeScreen8")

        _ = app.wmf_tapFirstButton(withTranslationIn: ["welcome-explore-continue-button"])


        // Useful if you temporarily comment out the welcome screens above.
        // _ = app.wmf_tapFirstButton(withTranslationIn: ["button-skip"])


        // Sleep for a bit to give Explore data some time to be fetched.
        sleep(6)
        // Scroll down a ways then back up to increase odds that feed elements are in place and won't be freshing underneath us while the code below scrolls and attempts to tap on elements.
        app.wmf_scrollDown(times: 20)
        _ = app.wmf_scrollToTop()


        // EXPLORE
        _ = app.wmf_tapFirstButton(withTranslationIn: ["home-title"])
        wmf_snapshot("ExploreScreen1")

        app.wmf_scrollToFirstElements(items:
            [
                // Picture of the day / Gallery
                ScrollItem(key: "explore-potd-heading", success: { element in
                    self.wmf_snapshot("ExploreScreenPicOfTheDay")
                    _ = element.wmf_tap()
                    sleep(8)
                    self.wmf_snapshot("GalleryScreen")
                    _ = self.app.wmf_tapFirstCloseButton()
                }),

                // Featured article
                ScrollItem(key: "explore-featured-article-heading", success: { element in
                    self.wmf_snapshot("ExploreScreenFeaturedArticle")
                }),

                // Top read
                ScrollItem(key: "explore-most-read-heading", success: { element in
                    self.wmf_snapshot("ExploreScreenMostRead")
                    _ = element.wmf_tap()
                    self.wmf_snapshot("MostReadDetail")
                    _ = self.app.wmf_tapFirstNavigationBarBackButton()
                }),

                // On this day
                ScrollItem(key: "on-this-day-title", success: { element in
                    self.wmf_snapshot("ExploreScreenOnThisDay")
                    _ = element.wmf_tap()
                    self.wmf_snapshot("OnThisDayDetail")
                    _ = self.app.wmf_tapFirstNavigationBarBackButton()
                }),
                
                // Nearby
                ScrollItem(key: "explore-nearby-placeholder-heading", success: { element in
                    self.wmf_snapshot("ExploreScreenNearbyPlaces")
                }),
                
                // Random article
                ScrollItem(key: "explore-random-article-heading", success: { element in
                    self.wmf_snapshot("ExploreScreenRandom")
                    _ = element.wmf_tap()
                    sleep(8)
                    self.wmf_snapshot("RandomDetail")
                    _ = self.app.wmf_tapFirstButton(withTranslationIn: ["button-save-for-later"])
                    sleep(2)
                    self.wmf_snapshot("RandomDetailSaved")
                    _ = self.app.wmf_tapFirstNavigationBarBackButton()
                }),
                
                // Main page
                ScrollItem(key: "explore-main-page-heading", success: { element in
                    self.wmf_snapshot("ExploreScreenMainPage")
                    _ = element.wmf_tap()
                    sleep(8)
                    self.wmf_snapshot("MainPageDetail")
                    _ = self.app.wmf_tapFirstNavigationBarBackButton()
                }),
                
                // In the news
                ScrollItem(key: "in-the-news-title", success: { element in
                    self.wmf_snapshot("ExploreScreenInTheNews")
                    _ = element.wmf_tap()
                    self.wmf_snapshot("InTheNewsDetail")
                    _ = self.app.wmf_tapFirstNavigationBarBackButton()
                })
            ]
        )

        
        // SEARCH
        _ = app.wmf_scrollToTop()
        let searchField = app.wmf_firstSearchField(withTranslationIn: ["search-field-placeholder-text"])
        if searchField.wmf_tap() {
            wmf_snapshot("SearchScreen1")
            if searchField.wmf_typeText(text: "a") {
                wmf_snapshot("SearchScreen2")
            }
        }
        
        
        // ARTICLE
        _ = app.wmf_tapFirstCollectionViewCell()
        sleep(8)
        wmf_snapshot("ArticleScreen1")
        sleep(8) // give popover time to disappear (this uitest target sleeps - the app doesn't)

        // TOC and ARTICLE FOOTERS
        if UIDevice.current.userInterfaceIdiom != .pad {
            // TOC
            _ = app.wmf_tapFirstButton(withTranslationIn: ["table-of-contents-button-label"])
            wmf_snapshot("ArticleScreenTOC")
            
            // `About this article` footer
            _ = app.wmf_tapFirstStaticText(withTranslationIn: ["article-about-title"])
            wmf_snapshot("ArticleScreenFooterAboutThisArticle")
            
            // Article history
            _ = app.wmf_tapFirstStaticText(withTranslationIn: ["page-last-edited"], convertTranslationSubstitutionStringsToWildcards: true)
            sleep(8)
            wmf_snapshot("ArticleScreenFooterArticleHistory")
            _ = app.wmf_tapFirstCloseButton()
            
            // `Read more` footer
            _ = app.wmf_tapFirstButton(withTranslationIn: ["table-of-contents-button-label"])
            _ = app.wmf_tapFirstStaticText(withTranslationIn: ["article-read-more-title"])
            wmf_snapshot("ArticleScreenFooterReadMore")
        } else {
            // Article footer (both the `About this article` and `Read more` footers are visible on larger iPad screens so no need to do separate screenshot for `Read more`)
            _ = app.wmf_tapFirstStaticText(withTranslationIn: ["article-about-title"])
            wmf_snapshot("ArticleScreenFooter")
        }
        
        
        // Article theme panel
        _ = app.wmf_tapFirstButton(withTranslationIn: ["article-toolbar-reading-themes-controls-toolbar-item"])
        wmf_snapshot("ArticleScreenThemesLight")
        
        _ = app.wmf_tapFirstButton(withTranslationIn: ["reading-themes-controls-accessibility-sepia-theme-button"])
        wmf_snapshot("ArticleScreenThemesSepia")

        _ = app.wmf_tapFirstButton(withTranslationIn: ["reading-themes-controls-accessibility-dark-theme-button"])
        wmf_snapshot("ArticleScreenThemesDark")

        _ = app.wmf_tapFirstButton(withTranslationIn: ["reading-themes-controls-accessibility-black-theme-button"])
        wmf_snapshot("ArticleScreenThemesBlack")

        _ = app.wmf_tapFirstButton(withTranslationIn: ["reading-themes-controls-accessibility-light-theme-button"])

        sleep(8) // give popover time to disappear (this uitest target sleeps - the app doesn't)

        
        // Article find in page
        _ = app.wmf_tapFirstButton(withTranslationIn: ["find-in-page-button-label"])
        wmf_snapshot("ArticleScreenFindInPage1")
        let textField = app.textFields.element(boundBy: 0).wmf_waitUntilExists()
        if textField.wmf_tap() {
            if textField.wmf_typeText(text: "a") {
                wmf_snapshot("ArticleScreenFindInPage2")
            }
        }
        _ = app.wmf_tapFirstCloseButton()
        _ = app.wmf_tapFirstButton(withTranslationIn: ["button-save-for-later"])
        
        _ = app.wmf_tapFirstButton(withTranslationIn: ["home-button-explore-accessibility-label"])

        
        // SETTINGS
        _ = app.wmf_tapFirstButton(withTranslationIn: ["settings-title"])
        wmf_snapshot("SettingsScreen1")


        // Login
        _ = app.wmf_tapFirstStaticText(withTranslationIn: ["main-menu-account-login"])
        wmf_snapshot("LoginScreen1")

        
        // Create account
        _ = app.wmf_tapFirstStaticText(withTranslationIn: ["login-no-account"], convertTranslationSubstitutionStringsToWildcards: true)
        wmf_snapshot("CreateAccountScreen1")
        _ = app.wmf_tapFirstCloseButton()

        
        // Forgot password
        _ = app.wmf_tapFirstStaticText(withTranslationIn: ["main-menu-account-login"])
        _ = app.wmf_tapFirstStaticText(withTranslationIn: ["login-forgot-password"])
        wmf_snapshot("ForgotPasswordScreen1")
        _ = app.wmf_tapFirstCloseButton()

        
        // My languages
        _ = app.wmf_tapFirstStaticText(withTranslationIn: ["settings-my-languages"])
        wmf_snapshot("MyLanguagesScreen1")
        _ = app.wmf_tapFirstCloseButton()


        // Notifications
        _ = app.wmf_tapFirstStaticText(withTranslationIn: ["settings-notifications"])
        wmf_snapshot("NotificationsScreen1")
        _ = app.wmf_tapFirstButton(withTranslationIn: ["settings-title"])

        
        // Reading preferences
        _ = app.wmf_tapFirstStaticText(withTranslationIn: ["settings-appearance"])
        wmf_snapshot("AppearanceScreen1")
        _ = app.wmf_tapFirstButton(withTranslationIn: ["settings-title"])

        
        // Article storage and syncing
        _ = app.wmf_tapFirstStaticText(withTranslationIn: ["settings-storage-and-syncing-title"])
        wmf_snapshot("StorageAndSyncingScreen1")
        _ = app.wmf_tapFirstButton(withTranslationIn: ["settings-title"])

        
        // Clear cached data
        _ = app.wmf_tapFirstStaticText(withTranslationIn: ["settings-clear-cache"])
        wmf_snapshot("ClearCacheScreen1")

        
        // Help and feedback
        _ = app.wmf_tapFirstStaticText(withTranslationIn: ["settings-help-and-feedback"])
        sleep(8)
        wmf_snapshot("HelpAndFeedbackScreen1")
        sleep(8) // give tooltip time to disappear (this uitest target sleeps - the app doesn't)
        _ = app.wmf_tapFirstButton(withTranslationIn: ["settings-title"])

        
        // About the app
        _ = app.wmf_tapFirstStaticText(withTranslationIn: ["main-menu-about"])
        sleep(8)
        wmf_snapshot("AboutTheAppScreen1")
        app.wmf_scrollDown()
        wmf_snapshot("AboutTheAppScreen2")
        app.wmf_scrollDown()
        wmf_snapshot("AboutTheAppScreen3")
        app.wmf_scrollDown()
        wmf_snapshot("AboutTheAppScreen4")


        // Libraries used
        _ = app.wmf_tapFirstStaticText(withTranslationIn: ["about-libraries-complete-list"])
        wmf_snapshot("AboutTheAppScreenLibrariesUsed")
        _ = app.wmf_tapFirstCloseButton()

        
        _ = app.wmf_tapFirstButton(withTranslationIn: ["settings-title"])
        _ = app.wmf_tapFirstCloseButton()

        
        // SAVED
        _ = app.wmf_tapFirstButton(withTranslationIn: ["saved-title"])
        wmf_snapshot("SavedScreen1")
        _ = app.wmf_tapFirstCloseButton()
        wmf_snapshot("SavedScreen2")

        
        // HISTORY
        _ = app.wmf_tapFirstButton(withTranslationIn: ["history-title"])
        wmf_snapshot("HistoryScreen1")

        
        // PLACES
        _ = app.wmf_tapFirstButton(withTranslationIn: ["places-title"])
        wmf_snapshot("PlacesScreen1")
    }
}

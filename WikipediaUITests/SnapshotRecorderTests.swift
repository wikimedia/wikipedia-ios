import XCTest

/*
 
RECORDS APP SCREENSHOTS FOR VARIOUS DEVICES AND LANGS:
 
- details: https://docs.fastlane.tools/actions/snapshot/
- run the `bundle exec fastlane snapshot` command to kick off the screenshot taking test below
(when debugging `wmf_localizedString:key:` below sometimes I needed to re-run this command before things behaved as expected, probably due to how `SnapshotHelper.swift` interacts with simulators & builds)
- see `/fastlane/snapfile` to configure (langs, simulators, other parameters, etc)


STEPS FOR ADDING/EDITING TESTS BELOW:
 
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
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        
        let app = XCUIApplication()

        
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
    
    // This UI test is used as a harness to navigate to various parts of the app and record screenshots. Fastlane snapshots don't seem to play nice with multiple tests taking snapshots, so we have all of them in this single test.
    func testRecordAppScreenshots() {
        
        let app = XCUIApplication()

         // WECOME
        snapshot("WelcomeScreen1")

        app.wmf_tapButton(key: "welcome-intro-free-encyclopedia-more")
        snapshot("WelcomeScreen2")

        app.wmf_tapButton(key: "welcome-explore-tell-me-more-done-button")
        snapshot("WelcomeScreen3")

        app.wmf_tapButton(key: "button-next")
        snapshot("WelcomeScreen4")

        app.wmf_tapButton(key: "button-next")
        snapshot("WelcomeScreen5")

        app.wmf_tapButton(key: "welcome-languages-add-or-edit-button")
        snapshot("WelcomeScreen6")

        app.wmf_tapButton(key: "close-button-accessibility-label")

        app.wmf_tapButton(key: "button-next")
        snapshot("WelcomeScreen7")
        app.wmf_tapButton(key: "welcome-explore-continue-button")

        // Useful if you temporarily comment out the welcome screens above.
        // app.wmf_tapButton(key: "button-skip")

        // EXPLORE
        app.wmf_tapButton(key: "home-title")
        snapshot("ExploreScreen1")

        // SEARCH
        app.wmf_tapSearchField(key: "search-field-placeholder-text")
        snapshot("SearchScreen1")
        app.wmf_searchField(key: "search-field-placeholder-text").typeText("a")
        snapshot("SearchScreen2")
        
        // ARTICLE
        app.wmf_tapFirstCollectionViewCell()
        sleep(8)
        snapshot("ArticleScreen1")
        sleep(10) // give popover time to disappear (this uitest target sleeps - the app doesn't)
        
        app.wmf_tapButton(key: "table-of-contents-button-label")
        snapshot("ArticleScreenTOC")
        app.wmf_tapButton(key: "table-of-contents-close-accessibility-label")
        
        app.wmf_tapButton(key: "article-toolbar-reading-themes-controls-toolbar-item")
        snapshot("ArticleScreenThemes")
        sleep(10) // give popover time to disappear (this uitest target sleeps - the app doesn't)

        app.wmf_tapButton(key: "find-in-page-button-label")
        snapshot("ArticleScreenFindInPage1")
        app.textFields.firstMatch.typeText("a")
        snapshot("ArticleScreenFindInPage2")

        app.wmf_tapUnlocalizedCloseButton()
        
        app.wmf_tapButton(key: "home-button-explore-accessibility-label")

        // SETTINGS
        app.wmf_tapButton(key: "settings-title")
        snapshot("SettingsScreen1")

        // Login
        app.wmf_tapStaticText(key: "main-menu-account-login")
        snapshot("LoginScreen1")
        app.wmf_tapUnlocalizedCloseButton()
        
        // Support Wikipedia
        // app.wmf_tapStaticText(key: "settings-support")
        // snapshot("SupportScreen1")
        // TODO: how do we get back from Safari popover?

        // My languages
        app.wmf_tapStaticText(key: "settings-my-languages")
        snapshot("MyLanguagesScreen1")
        app.wmf_tapButton(key: "close-button-accessibility-label")

        // NOT NEEDED - just a toggle
        // Show languages on search
        // app.wmf_tapStaticText(key: "settings-language-bar")
        // snapshot("LanguageBarScreen1")

        // Notifications
        app.wmf_tapStaticText(key: "settings-notifications")
        snapshot("NotificationsScreen1")
        app.wmf_tapButton(key: "settings-title")

        // Reading preferences
        app.wmf_tapStaticText(key: "settings-appearance")
        snapshot("AppearanceScreen1")
        app.wmf_tapButton(key: "settings-title")

        // Article storage and syncing
        app.wmf_tapStaticText(key: "settings-storage-and-syncing-title")
        snapshot("StorageAndSyncingScreen1")
        app.wmf_tapButton(key: "settings-title")

        // Clear cached data
        app.wmf_tapStaticText(key: "settings-clear-cache")
        snapshot("ClearCacheScreen1")

        // Privacy policy
        // app.wmf_tapStaticText(key: "main-menu-privacy-policy")
        // snapshot("PrivacyPolicyScreen1")
        // TODO: how do we get back from Safari popover?

        // Terms of use
        // app.wmf_tapStaticText(key: "main-menu-terms-of-use")
        // snapshot("TermsOfUseScreen1")
        // TODO: how do we get back from Safari popover?

        // NOT NEEDED - just a toggle
        // Send usage reports
        // app.wmf_tapStaticText(key: "preference-title-eventlogging-opt-in")
        // snapshot("EventLoggingOptInScreen1")

        // Wikipedia Zero FAQ
        // app.wmf_tapStaticText(key: "main-menu-zero-faq")
        // snapshot("ZeroFAQScreen1")
        // TODO: how do we get back from Safari popover?

        // Rate the app
        // app.wmf_tapStaticText(key: "main-menu-rate-app")
        // snapshot("RateAppScreen1")
        // TODO: how do we get back from Safari popover?

        // Help and feedback
        app.wmf_tapStaticText(key: "settings-help-and-feedback")
        snapshot("HelpAndFeedbackScreen1")
        sleep(10) // give tooltip time to disappear (this uitest target sleeps - the app doesn't)
        app.wmf_tapButton(key: "settings-title")

        // About the app
        app.wmf_tapStaticText(key: "main-menu-about")
        snapshot("AboutTheAppScreen1")
        app.wmf_tapButton(key: "settings-title")

        app.wmf_tapButton(key: "close-button-accessibility-label")

        // SAVED
        app.wmf_tapButton(key: "saved-title")
        snapshot("SavedScreen1")

        // HISTORY
        app.wmf_tapButton(key: "history-title")
        snapshot("HistoryScreen1")

        // PLACES
        app.wmf_tapButton(key: "places-title")
        snapshot("PlacesScreen1")
    }
}

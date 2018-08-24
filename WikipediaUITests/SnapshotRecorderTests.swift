import XCTest

// Details: see `README.md` in same folder as this file.

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

        let iPhoneXSafeTopOffset: CGFloat = 0.04 // As of Xcode 9.4 an offset of 0 drags elements a little too far up.

        app.wmf_scrollToFirstElements(matching: .link, yOffset: iPhoneXSafeTopOffset, items:
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
                ScrollItem(key: "explore-most-read-generic-heading", success: { element in
                    self.wmf_snapshot("ExploreScreenMostRead")
                    _ = element.wmf_tap()
                    self.wmf_snapshot("MostReadDetail")
                    _ = self.app.wmf_tapFirstCloseButton()
                }),

                // On this day
                ScrollItem(key: "on-this-day-title", success: { element in
                    self.wmf_snapshot("ExploreScreenOnThisDay")
                    _ = element.wmf_tap()
                    self.wmf_snapshot("OnThisDayDetail")
                    _ = self.app.wmf_tapFirstCloseButton()
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
                    _ = self.app.wmf_tapFirstCloseButton()
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
            
            app.wmf_scrollToFirstElements(matching: .staticText, yOffset: 0.1, items:
                [
                    ScrollItem(key: "article-about-title", success: { element in
                        // `About this article` footer
                        _ = element.wmf_tap()
                        self.wmf_snapshot("ArticleScreenFooterAboutThisArticle")
                        
                        // Article history
                        _ = self.app.wmf_tapFirstStaticText(withTranslationIn: ["page-last-edited"], convertTranslationSubstitutionStringsToWildcards: true)
                        sleep(8)
                        self.wmf_snapshot("ArticleScreenFooterArticleHistory")
                        _ = self.app.wmf_tapFirstCloseButton()
                    })
                ]
            )
            
            _ = app.wmf_tapFirstButton(withTranslationIn: ["table-of-contents-button-label"])

            app.wmf_scrollToFirstElements(matching: .staticText, yOffset: 0.1, items:
                [
                    ScrollItem(key: "article-read-more-title", success: { element in
                        // `Read more` footer
                        _ = element.wmf_tap()
                        self.wmf_snapshot("ArticleScreenFooterReadMore")
                    })
                ]
            )
        } else {
            app.wmf_scrollToFirstElements(matching: .staticText, yOffset: 0.1, items:
                [
                    ScrollItem(key: "article-about-title", success: { element in
                        // `About this article` footer
                        _ = element.wmf_tap()
                        self.wmf_snapshot("ArticleScreenFooter")
                    })
                ]
            )
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

        
        app.wmf_scrollToFirstElements(matching: .staticText, yOffset: 0.13, items:
            [
                // Login
                ScrollItem(key: "main-menu-account-login", success: { element in
                    _ = element.wmf_tap()
                    sleep(2)
                    self.wmf_snapshot("LoginScreen1")

                    // Create account
                    _ = self.app.wmf_tapFirstStaticText(withTranslationIn: ["login-no-account"], convertTranslationSubstitutionStringsToWildcards: true)
                    self.wmf_snapshot("CreateAccountScreen1")
                    _ = self.app.wmf_tapFirstCloseButton()

                    // Forgot password
                    _ = element.wmf_tap()
                    _ = self.app.wmf_tapFirstStaticText(withTranslationIn: ["login-forgot-password"])
                    self.wmf_snapshot("ForgotPasswordScreen1")
                    _ = self.app.wmf_tapFirstCloseButton()
                }),
                // My languages
                ScrollItem(key: "settings-my-languages", success: { element in
                    _ = element.wmf_tap()
                    sleep(2)
                    self.wmf_snapshot("MyLanguagesScreen1")
                    _ = self.app.wmf_tapFirstCloseButton()
                }),
                // Notifications
                ScrollItem(key: "settings-notifications", success: { element in
                    _ = element.wmf_tap()
                    sleep(2)
                    self.wmf_snapshot("NotificationsScreen1")
                    _ = self.app.wmf_tapFirstButton(withTranslationIn: ["settings-title"])
                }),
                // Reading preferences
                ScrollItem(key: "settings-appearance", success: { element in
                    _ = element.wmf_tap()
                    self.wmf_snapshot("AppearanceScreen1")
                    _ = self.app.wmf_tapFirstButton(withTranslationIn: ["settings-title"])
                }),
                // Article storage and syncing
                ScrollItem(key: "settings-storage-and-syncing-title", success: { element in
                    _ = element.wmf_tap()
                    self.wmf_snapshot("StorageAndSyncingScreen1")
                    _ = self.app.wmf_tapFirstButton(withTranslationIn: ["settings-title"])
                }),
                // Clear cached data
                ScrollItem(key: "settings-clear-cache", success: { element in
                    _ = element.wmf_tap()
                    self.wmf_snapshot("ClearCacheScreen1")
                }),
                // Help and feedback
                ScrollItem(key: "settings-help-and-feedback", success: { element in
                    _ = element.wmf_tap()
                    sleep(4)
                    self.wmf_snapshot("HelpAndFeedbackScreen1")
                    sleep(8) // give tooltip time to disappear (this uitest target sleeps - the app doesn't)
                    _ = self.app.wmf_tapFirstButton(withTranslationIn: ["settings-title"])
                }),
                // About the app
                ScrollItem(key: "main-menu-about", success: { element in
                    _ = element.wmf_tap()
                    sleep(8)
                    self.wmf_snapshot("AboutTheAppScreen1")
                    self.app.wmf_scrollDown()
                    self.wmf_snapshot("AboutTheAppScreen2")
                    self.app.wmf_scrollDown()
                    self.wmf_snapshot("AboutTheAppScreen3")

                    self.app.webViews.element(boundBy: 0).wmf_waitUntilExists(timeout: 1.0)?.wmf_scrollToFirstElements(matching: .staticText, yOffset: 0.1, items:
                        [
                            // Libraries used
                            ScrollItem(key: "about-libraries-complete-list", success: { element in
                                _ = element.wmf_tap()
                                self.wmf_snapshot("AboutTheAppScreenLibrariesUsed")
                                _ = self.app.wmf_tapFirstCloseButton()
                            })
                        ]
                    )

                    _ = self.app.wmf_tapFirstButton(withTranslationIn: ["settings-title"])
                    _ = self.app.wmf_tapFirstCloseButton()
                }),
                // Explore feed
                ScrollItem(key: "welcome-exploration-explore-feed-title", success: { element in
                    _ = element.wmf_tap()
                    self.wmf_snapshot("ExploreCustomizationScreen1")
                    _ = self.app.wmf_tapFirstButton(withTranslationIn: ["settings-title"])
                }),
                // Search
                ScrollItem(key: "search-title", success: { element in
                    _ = element.wmf_tap()
                    self.wmf_snapshot("SearchCustomizationScreen1")
                    _ = self.app.wmf_tapFirstButton(withTranslationIn: ["settings-title"])
                })
            ]
        )

        
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

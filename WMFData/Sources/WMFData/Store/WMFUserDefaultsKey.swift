public enum WMFUserDefaultsKey: String {
    case watchlistFilterSettings = "watchlist-filter-settings"
    case imageRecommendationsOnboarding = "image-recommendations-onboarding"
    case developerSettingsEnableDeveloperMode = "dev-enable-developer-mode"
    case developerSettingsDoNotPostImageRecommendationsEdit = "dev-settings-do-not-post-image-rec-edit"
    case developerSettingsSendAnalyticsToWMFLabs = "dev-settings-send-analytics-to-wmflabs"
    case developerSettingsArticleTab = "dev-settings-article-tab"
    case developerSettingsForceMaxArticleTabsTo5 = "dev-settings-article-tab-max-5"
    case developerSettingsEnableHomeTab = "dev-settings-enable-home-tab"
    case developerSettingsAlwaysShowNewOnboarding = "dev-settings-always-show-new-onboarding"
    case hasLocallySavedDonations = "donate-history-has-locally-saved-donations"
    case yearInReviewSettingsIsEnabled = "year-in-review-settings-is-enabled-v3"
    case seenYearInReviewFeatureAnnouncement = "year-in-review-feature-announcement-v3"
    case yearInReviewSurveyPresented = "year-in-review-survey-presented-v3"
    case bypassDonation = "bypass-donation"
    case seenYearInReviewIntroSlide = "seen-year-in-review-intro-slide-v3"
    case tappedYIR = "tapped-yir"
    case forceEmailAuth = "force-email-auth"
    case articleTabRestoration = "article-tab-restoration"
    case articleTabsOverviewOpenedCount = "article-tabs-overview-opened-count"
    case articleTabsOverviewOpenedCountBandC = "article-tabs-overview-opened-count-b-and-c"
    case articleTabsDidTapOpenInNewTab = "article-tabs-did-tap-open-in-new-tab"
    case articleTabsDidShowSurvey = "article-tabs-did-show-survey"
    case articleTabsDidShowSurveyBandC = "article-tabs-did-show-survey-b-and-c"
    case developerSettingsMoreDynamicTabsV2GroupC = "more-dynamic-tabs-group-c-v2"
    case developerSettingsShowYiR2025 = "dev-settings-yir-show-v3"
    case developerSettingsYiRV3LoginExperimentControl = "dev-settings-yir-login-experiment-control"
    case developerSettingsYiRV3LoginExperimentB = "dev-settings-yir-login-experiment-b"
    case yearInReviewNewIcon2025 = "year-in-review-new-icon-2025"
    case qualifiesForIcon2025 = "qualifies-for-icon-2025"
    case userHasHiddenArticleSuggestionsTabs = "user-has-hidden-article-suggestions"
    case hasSeenActivityTab = "has-seen-activity-tab"
    case hasSeenActivityTabNewOnboarding = "has-seen-activity-tab-new-onboarding"
    case hasSeenActiviyTabSurvey = "has-seen-activity-tab-survey"
    case activityTabVisitCount = "activity-tab-visit-count"
    case activityTabIsTimeSpentReadingOn = "activity-tab-time-spent-reading"
    case activityTabIsReadingInsightsOn = "activity-tab-reading-insights"
    case activityTabIsEditingInsightsOn = "activity-tab-editing-insights"
    case activityTabIsTimelineOfBehaviorOn = "activity-tab-timeline-of-behavior"
    case autoSignTalkPageDiscussions = "auto-sign-talk-page-discussions"
    case didMigrateAutoSignTalkPageDiscussions = "did-migrate-auto-sign-talk-page-discussions"
    case showSearchLanguageBar = "show-search-language-bar"
    case openAppOnSearchTab = "open-app-on-search-tab"
    case isSubscribedToEchoNotifications = "is-subscribed-to-echo-notifications"
    case forceHCaptchaChallenge = "force-hcaptcha-challenge"

    case allowGestureZoomArticleWebview = "allow-gesture-zoom-article-webview"

    // Games announcement
    case hasSeenGamesAnnouncement = "has-seen-games-announcement"
    case needsDailyGameFeedRefresh = "needs-daily-game-feed-refresh"

    // Games dev settings
    case developerSettingsShowGamesV2 = "dev-settings-show-games-v2"

    // Logging
    case appInstallID = "wmf-app-install-id"
    case sessionID = "wmf-session-id"

    // Home feed: Community modules
    case homeFeedCommunityFeaturedArticleIsOn = "home-feed-community-featured-article-is-on"
    case homeFeedCommunityTopReadIsOn = "home-feed-community-top-read-is-on"
    case homeFeedCommunityInTheNewsIsOn = "home-feed-community-in-the-news-is-on"
    case homeFeedCommunityOnThisDayIsOn = "home-feed-community-on-this-day-is-on"
    case homeFeedCommunityPictureOfTheDayIsOn = "home-feed-community-picture-of-the-day-is-on"

    // Home feed: For You modules
    case homeFeedForYouBasedOnInterestsIsOn = "home-feed-for-you-based-on-interests-is-on"
    case homeFeedForYouBecauseYouReadIsOn = "home-feed-for-you-because-you-read-is-on"
    case homeFeedForYouContinueReadingIsOn = "home-feed-for-you-continue-reading-is-on"

    // Home feed: selected language
    case homeSelectedLanguage = "home-selected-language-code"

    // Home feed: initial content preference (community vs personalized)
    case homeFeedSeeFirst = "home-feed-see-first"

    // Home feed: interests
    case homeFeedInterestTopics = "home-feed-interest-topics"

    // Home feed: hidden cards (shared across Community and For You tabs)
    case homeFeedHiddenCardKeys = "home-feed-hidden-card-keys"
    
    case randomWidgetDailyIndex = "random-widget-daily-index"
    case randomWidgetDailyDate = "random-widget-daily-date"

    // Onboarding: New app install event
    case didSendNewInstallOnboardingStartEvent = "did-send-new-install-onboarding-start-event"
}

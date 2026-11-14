import Foundation
import Testing
@testable import WMFComponents

extension WMFActivityTabViewModel.LocalizedStrings {
    static var testStrings: WMFActivityTabViewModel.LocalizedStrings {
        WMFActivityTabViewModel.LocalizedStrings(
            userNamesReading: { "\($0) is reading" },
            noUsernameReading: "Someone is reading",
            totalHoursMinutesRead: { "\($0)h \($1)m" },
            onWikipediaiOS: "",
            timeSpentReading: "",
            totalArticlesRead: "",
            week: "",
            articlesRead: "",
            topCategories: "",
            articlesSavedTitle: "",
            remaining: { _ in "" },
            loggedOutTitle: "",
            loggedOutSubtitle: "",
            loggedOutPrimaryCTA: "",
            yourImpact: "",
            todayTitle: "",
            yesterdayTitle: "",
            openArticle: "",
            deleteAccessibilityLabel: "",
            totalEditsAcrossProjects: "",
            read: "",
            edited: "",
            saved: "",
            emptyViewTitleLoggedIn: "Empty, logged in",
            emptyViewSubtitleLoggedIn: "",
            emptyViewTitleLoggedOut: "Empty, logged out",
            emptyViewSubtitleLoggedOut: "",
            customizeTimeSpentReading: "",
            customizeReadingInsights: "",
            customizeEditingInsights: "",
            customizeAllTimeImpact: "",
            customizeLastInAppDonation: "",
            customizeTimelineOfBehavior: "",
            customizeFooter: "",
            customizeEmptyState: "",
            viewChanges: "",
            contributionsThisMonth: "",
            thisMonth: "",
            lastMonth: "",
            lookingForSomethingNew: "",
            exploreWikipedia: "",
            zeroEditsToArticles: "",
            looksLikeYouHaventMadeAnEdit: "",
            makeAnEdit: "",
            viewsString: { _ in "" },
            mostViewed: "",
            allTimeImpactTitle: "",
            totalEditsLabel: "",
            bestStreakValue: { _ in "" },
            bestStreakLabel: "",
            thanksLabel: "",
            lastEditedLabel: "",
            yourRecentActivityTitle: "",
            editsLabel: "",
            startEndDatesAccessibilityLabel: { _, _ in "" },
            viewsOnArticlesYouveEditedTitle: "",
            lineGraphDay: "",
            lineGraphViews: "",
            historyCalloutTitle: "",
            historyCalloutBodyLoggedIn: "",
            historyCalloutBodyLoggedOut: "",
            calloutCloseButtonAccesibilityHint: ""
        )
    }
}

/// Waits on a condition rather than a duration, for work that the code under test starts without
/// handing back a task to await. The timeout only bounds a failure, so it cannot fail a slow pass.
@MainActor
func waitForActivityTabCondition(_ condition: () async throws -> Bool) async throws {
    let deadline = ContinuousClock.now + .seconds(20)
    while ContinuousClock.now < deadline {
        if try await condition() {
            return
        }
        try await Task.sleep(for: .milliseconds(10))
    }
    Issue.record("The condition did not become true before the timeout.")
}

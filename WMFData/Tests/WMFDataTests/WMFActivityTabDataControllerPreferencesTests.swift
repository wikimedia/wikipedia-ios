import Foundation
import Testing
import WMFDataTestSupport
@testable import WMFData
@testable import WMFDataMocks

/// The customization toggles, the onboarding flag, the survey gate and the two account-scoped
/// fetches all read through `WMFDataEnvironment.current` rather than through an injected store,
/// so this suite leases the global environment instead of constructing one.
@Suite(.serialized)
final class WMFActivityTabDataControllerPreferencesTests {

    private let fixture = WMFDataTestFixture()

    private func configureEnvironment() async {
        WMFDataEnvironment.current.userDefaultsStore = WMFMockKeyValueStore()
        WMFDataEnvironment.current.appData = WMFAppData(appLanguages: [])
    }

    /// Every Activity tab module is opt-out: with nothing written yet, all four read as on.
    @Test
    func customizationTogglesDefaultToOn() async {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let dataController = WMFActivityTabDataController()

            #expect(await dataController.isTimeSpentReadingOn)
            #expect(await dataController.isReadingInsightsOn)
            #expect(await dataController.isEditingInsightsOn)
            #expect(await dataController.isTimelineOfBehaviorOn)
        }
    }

    /// Each toggle has to survive a write and come back, in both directions - a store that silently
    /// dropped the value would otherwise look identical to the opt-out default.
    @Test
    func customizationTogglesRoundTripThroughTheStore() async {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let dataController = WMFActivityTabDataController()

            await dataController.updateIsTimeSpentReadingOn(false)
            await dataController.updateIsReadingInsightsOn(false)
            await dataController.updateIsEditingInsightsOn(false)
            await dataController.updateIsTimelineOfBehaviorOn(false)

            #expect(await dataController.isTimeSpentReadingOn == false)
            #expect(await dataController.isReadingInsightsOn == false)
            #expect(await dataController.isEditingInsightsOn == false)
            #expect(await dataController.isTimelineOfBehaviorOn == false)

            await dataController.updateIsTimeSpentReadingOn(true)
            #expect(await dataController.isTimeSpentReadingOn, "Turning a module back on has to stick too.")
        }
    }

    /// The four toggles are near-identical accessors over four different keys, which is exactly the
    /// shape a copy-paste mistake hides in. Turning one off must leave the other three alone.
    @Test
    func turningOffOneToggleLeavesTheOthersOn() async {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let dataController = WMFActivityTabDataController()

            await dataController.updateIsEditingInsightsOn(false)

            #expect(await dataController.isEditingInsightsOn == false)
            #expect(await dataController.isTimeSpentReadingOn)
            #expect(await dataController.isReadingInsightsOn)
            #expect(await dataController.isTimelineOfBehaviorOn)
        }
    }

    /// Onboarding is the inverse default of the toggles: unseen until it is explicitly recorded.
    @Test
    func hasSeenActivityTabDefaultsToFalseAndRoundTrips() async {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let dataController = WMFActivityTabDataController()

            #expect(await dataController.getHasSeenActivityTab() == false)

            await dataController.setHasSeenActivityTab(true)
            #expect(await dataController.getHasSeenActivityTab())
        }
    }

    /// The survey has three gates: at least three visits, not already dismissed, and a hard end date
    /// of 2026-04-15. That date has passed, so the survey is now off for everyone regardless of the
    /// first two gates. This pins both the date and the fact that it is what closes the survey - if
    /// the window is ever reopened, the date expectations below fail and say so.
    @Test
    func surveyIsGatedOffOnceItsEndDateHasPassed() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let dataController = WMFActivityTabDataController()

            let endDate = try #require(await dataController.surveyEndDate)
            let components = Calendar.current.dateComponents([.year, .month, .day], from: endDate)
            #expect(components.year == 2026)
            #expect(components.month == 4)
            #expect(components.day == 15)
            #expect(endDate < Date(), "The survey window has closed; the expectations below depend on it.")

            // Gate one: fewer than three visits.
            #expect(await dataController.shouldShowSurvey() == false)

            for _ in 0..<3 {
                await dataController.incrementActivityTabVisitCount()
            }

            // Three visits and never dismissed, but the end date still shuts it off.
            #expect(await dataController.shouldShowSurvey() == false)

            // Gate two, for completeness.
            await dataController.setHasSeenSurvey(value: true)
            #expect(await dataController.shouldShowSurvey() == false)
        }
    }

    /// With no app language configured there is no project to build a request for. Both account
    /// fetches must throw rather than force-unwrap their way into a crash.
    @Test
    func accountFetchesThrowWhenThereIsNoAppLanguage() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let dataController = WMFActivityTabDataController()

            #expect(WMFDataEnvironment.current.primaryAppLanguage == nil, "Premise of this test.")

            await #expect(throws: WMFActivityTabDataController.CustomError.self) {
                _ = try await dataController.getGlobalEditCount()
            }

            await #expect(throws: WMFDataControllerError.self) {
                _ = try await dataController.getUserImpactData(userID: 1)
            }
        }
    }
}

import Foundation
import Testing
import WMFDataTestSupport
@testable import WMFData
@testable import WMFDataMocks

@Suite(.serialized)
final class WMFDonationReminderDataControllerTests {

    private let fixture = WMFDataTestFixture()
    private let controller = WMFDonationReminderDataController.shared

    @Test
    func saveAndLoadArticleBasedReminder() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let createdDate = Date(timeIntervalSince1970: 1_755_600_000)
            let reminder = WMFDonationReminder(trigger: .articlesRead(count: 5), amount: 2, currencyCode: "EUR", createdDate: createdDate, isEnabled: true)

            controller.saveReminder(reminder)

            let loadedReminder = try #require(controller.loadReminder())
            #expect(loadedReminder == reminder)
            #expect(loadedReminder.trigger == .articlesRead(count: 5))
            #expect(loadedReminder.amount == 2)
            #expect(loadedReminder.currencyCode == "EUR")
            #expect(loadedReminder.isEnabled == true)
        }
    }

    @Test
    func saveAndLoadTimeBasedReminder() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let createdDate = Date(timeIntervalSince1970: 1_755_600_000)
            let reminder = WMFDonationReminder(trigger: .timeElapsed(days: 14), amount: 10.50, currencyCode: "EUR", createdDate: createdDate, isEnabled: true)

            controller.saveReminder(reminder)

            let loadedReminder = try #require(controller.loadReminder())
            #expect(loadedReminder.trigger == .timeElapsed(days: 14))
            #expect(loadedReminder.amount == Decimal(string: "10.50"))
        }
    }

    @Test
    func saveOverwritesPreviousReminder() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let createdDate = Date(timeIntervalSince1970: 1_755_600_000)
            controller.saveReminder(WMFDonationReminder(trigger: .articlesRead(count: 5), amount: 2, currencyCode: "EUR", createdDate: createdDate, isEnabled: true))
            controller.saveReminder(WMFDonationReminder(trigger: .articlesRead(count: 20), amount: 5, currencyCode: "EUR", createdDate: createdDate, isEnabled: false))

            let loadedReminder = try #require(controller.loadReminder())
            #expect(loadedReminder.trigger == .articlesRead(count: 20))
            #expect(loadedReminder.amount == 5)
            #expect(loadedReminder.isEnabled == false)
        }
    }

    @Test
    func loadWithoutSavedReminderReturnsNil() async {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            #expect(controller.loadReminder() == nil)
        }
    }

    @Test
    func clearRemovesSavedReminder() async {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let createdDate = Date(timeIntervalSince1970: 1_755_600_000)
            controller.saveReminder(WMFDonationReminder(trigger: .articlesRead(count: 10), amount: 1, currencyCode: "EUR", createdDate: createdDate, isEnabled: true))

            controller.clearReminder()

            #expect(controller.loadReminder() == nil)
        }
    }

    // MARK: - Follow-up Reminder Cycle

    @Test
    func articlesReadInCurrentCycleCountsQualifyingViewsSinceCycleStart() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironmentWithCoreData) {
            let createdDate = Date(timeIntervalSince1970: 1_755_600_000)
            controller.saveReminder(WMFDonationReminder(trigger: .articlesRead(count: 5), amount: 3, currencyCode: "EUR", createdDate: createdDate, isEnabled: true))

            try await addQualifyingPageView(title: "Before_Pledge", timestamp: createdDate.addingTimeInterval(-100))
            try await addQualifyingPageView(title: "After_Pledge", timestamp: createdDate.addingTimeInterval(100))
            try await addPageView(title: "Too_Short", timestamp: createdDate.addingTimeInterval(200), numberOfSeconds: 0)

            let articlesRead = try await controller.articlesReadInCurrentCycle(currentDate: createdDate.addingTimeInterval(1_000))
            #expect(articlesRead == 1)
        }
    }

    @Test
    func shouldShowFollowUpReminderRequiresReminderAndGoal() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironmentWithCoreData) {
            let createdDate = Date(timeIntervalSince1970: 1_755_600_000)
            let currentDate = createdDate.addingTimeInterval(1_000)
            controller.saveReminder(WMFDonationReminder(trigger: .articlesRead(count: 2), amount: 3, currencyCode: "EUR", createdDate: createdDate, isEnabled: true))

            try await addQualifyingPageView(title: "First", timestamp: createdDate.addingTimeInterval(100))
            #expect(try await controller.shouldShowFollowUpReminder(currentDate: currentDate) == false)

            try await addQualifyingPageView(title: "Second", timestamp: createdDate.addingTimeInterval(200))
            #expect(try await controller.shouldShowFollowUpReminder(currentDate: currentDate) == true)
        }
    }

    @Test
    func shouldShowFollowUpReminderIsFalseWhenReminderIsDisabled() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironmentWithCoreData) {
            let createdDate = Date(timeIntervalSince1970: 1_755_600_000)
            controller.saveReminder(WMFDonationReminder(trigger: .articlesRead(count: 1), amount: 3, currencyCode: "EUR", createdDate: createdDate, isEnabled: false))

            try await addQualifyingPageView(title: "First", timestamp: createdDate.addingTimeInterval(100))

            #expect(try await controller.shouldShowFollowUpReminder(currentDate: createdDate.addingTimeInterval(1_000)) == false)
        }
    }

    @Test
    func recordFollowUpReminderShownStartsANewCycleAndCountsAnImpression() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironmentWithCoreData) {
            let createdDate = Date(timeIntervalSince1970: 1_755_600_000)
            controller.saveReminder(WMFDonationReminder(trigger: .articlesRead(count: 1), amount: 3, currencyCode: "EUR", createdDate: createdDate, isEnabled: true))

            try await addQualifyingPageView(title: "First", timestamp: createdDate.addingTimeInterval(100))
            #expect(try await controller.shouldShowFollowUpReminder(currentDate: createdDate.addingTimeInterval(1_000)) == true)

            controller.recordFollowUpReminderShown(currentDate: createdDate.addingTimeInterval(1_000))

            let reminder = try #require(controller.loadReminder())
            #expect(reminder.timesReminderShown == 1)
            #expect(try await controller.articlesReadInCurrentCycle(currentDate: createdDate.addingTimeInterval(2_000)) == 0)
        }
    }

    @Test
    func reminderShowsAtMostOncePerDay() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironmentWithCoreData) {
            let createdDate = Date(timeIntervalSince1970: 1_755_600_000)
            let nextDay = createdDate.addingTimeInterval(100_000)
            controller.saveReminder(WMFDonationReminder(trigger: .articlesRead(count: 1), amount: 3, currencyCode: "EUR", createdDate: createdDate, isEnabled: true))

            controller.recordFollowUpReminderShown(currentDate: createdDate.addingTimeInterval(1_000))

            let shouldShowSameDay = try await controller.shouldShowFollowUpReminder(currentDate: createdDate.addingTimeInterval(2_000))
            #expect(shouldShowSameDay == false)

            let shouldShowNextDay = try await controller.shouldShowFollowUpReminder(currentDate: nextDay)
            #expect(shouldShowNextDay == true)

            WMFDeveloperSettingsDataController.shared.bypassDonationReminderDailyLimit = true
            let shouldShowSameDayWithBypass = try await controller.shouldShowFollowUpReminder(currentDate: createdDate.addingTimeInterval(2_000))
            #expect(shouldShowSameDayWithBypass == true)
        }
    }

    @Test
    func secondIgnoredImpressionClosesTheWindowUntilTheNextGoal() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironmentWithCoreData) {
            let createdDate = Date(timeIntervalSince1970: 1_755_600_000)
            let secondDay = createdDate.addingTimeInterval(100_000)
            let thirdDay = createdDate.addingTimeInterval(200_000)
            controller.saveReminder(WMFDonationReminder(trigger: .articlesRead(count: 1), amount: 3, currencyCode: "EUR", createdDate: createdDate, isEnabled: true))

            controller.recordFollowUpReminderShown(currentDate: createdDate.addingTimeInterval(1_000))
            controller.recordFollowUpReminderShown(currentDate: secondDay)

            #expect(try await controller.shouldShowFollowUpReminder(currentDate: thirdDay) == false)

            try await addQualifyingPageView(title: "After_Second_Impression", timestamp: thirdDay.addingTimeInterval(100))
            #expect(try await controller.shouldShowFollowUpReminder(currentDate: thirdDay.addingTimeInterval(1_000)) == true)
        }
    }

    @Test
    func impressionLimitDoesNotCloseTheWindow() async {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let createdDate = Date(timeIntervalSince1970: 1_755_600_000)
            let secondDay = createdDate.addingTimeInterval(100_000)
            controller.saveReminder(WMFDonationReminder(trigger: .articlesRead(count: 1), amount: 3, currencyCode: "EUR", createdDate: createdDate, isEnabled: true))

            controller.recordFollowUpReminderShown(currentDate: createdDate.addingTimeInterval(1_000))
            controller.recordFollowUpReminderShown(currentDate: secondDay)

            #expect(controller.loadReminder()?.timesReminderShown == 2)
            #expect(controller.isFollowUpReminderWindowClosed == false)
        }
    }

    @Test
    func aNewCycleReopensTheWindow() async {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let createdDate = Date(timeIntervalSince1970: 1_755_600_000)
            let progress = WMFDonationReminder.Progress(currentCycleStartDate: createdDate, timesReminderShown: 2, isWindowClosed: true)
            controller.saveReminder(WMFDonationReminder(trigger: .articlesRead(count: 1), amount: 3, currencyCode: "EUR", createdDate: createdDate, isEnabled: true, progress: progress))
            #expect(controller.isFollowUpReminderWindowClosed == true)

            controller.recordFollowUpReminderShown(currentDate: createdDate.addingTimeInterval(100_000))

            #expect(controller.loadReminder()?.timesReminderShown == 1)
            #expect(controller.isFollowUpReminderWindowClosed == false)
        }
    }

    @Test
    func wrapUpCardIsTheFeedbackSurveyForGroupBInsideTheWindow() async {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let insideWindowDate = WMFDonationReminderDataController.reminderEndDate.addingTimeInterval(3_600)
            let beforeWindowDate = WMFDonationReminderDataController.reminderEndDate.addingTimeInterval(-3_600)
            let atWindowEndDate = WMFDonationReminderDataController.wrapUpEndDate

            WMFDeveloperSettingsDataController.shared.forceDonationReminderExperimentAssignment = .groupB
            #expect(controller.wrapUpCardToShow(currentDate: insideWindowDate) == .feedbackSurvey)
            #expect(controller.wrapUpCardToShow(currentDate: beforeWindowDate) == nil)
            #expect(controller.wrapUpCardToShow(currentDate: atWindowEndDate) == nil)

            WMFDeveloperSettingsDataController.shared.forceDonationReminderExperimentAssignment = .groupC
            #expect(controller.wrapUpCardToShow(currentDate: insideWindowDate) == nil)

            WMFDeveloperSettingsDataController.shared.forceDonationReminderExperimentAssignment = .control
            #expect(controller.wrapUpCardToShow(currentDate: insideWindowDate) == nil)

            WMFDeveloperSettingsDataController.shared.forceDonationReminderExperimentAssignment = nil
        }
    }

    @Test
    func wrapUpCardIsTheRecurringPromptForGroupCWithAnEnabledReminder() async {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            WMFDeveloperSettingsDataController.shared.forceDonationReminderExperimentAssignment = .groupC
            let insideWindowDate = WMFDonationReminderDataController.reminderEndDate.addingTimeInterval(3_600)

            #expect(controller.wrapUpCardToShow(currentDate: insideWindowDate) == nil)

            controller.saveReminder(WMFDonationReminder(trigger: .articlesRead(count: 5), amount: 3, currencyCode: "EUR", createdDate: Date(timeIntervalSince1970: 1_700_000_000), isEnabled: false))
            #expect(controller.wrapUpCardToShow(currentDate: insideWindowDate) == nil)

            controller.saveReminder(WMFDonationReminder(trigger: .articlesRead(count: 5), amount: 3, currencyCode: "EUR", createdDate: Date(timeIntervalSince1970: 1_700_000_000), isEnabled: true))
            #expect(controller.wrapUpCardToShow(currentDate: insideWindowDate) == .recurringDonorPrompt(pledgeAmount: 3, currencyCode: "EUR"))

            WMFDeveloperSettingsDataController.shared.forceDonationReminderExperimentAssignment = nil
        }
    }

    @Test
    func wrapUpCardImpressionClaimsOnlyOnce() async {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            WMFDeveloperSettingsDataController.shared.forceDonationReminderExperimentAssignment = .groupB
            let insideWindowDate = WMFDonationReminderDataController.reminderEndDate.addingTimeInterval(3_600)

            #expect(controller.claimWrapUpCardImpression(currentDate: insideWindowDate) == .feedbackSurvey)
            #expect(controller.hasSeenWrapUpCard)
            #expect(controller.claimWrapUpCardImpression(currentDate: insideWindowDate) == nil)
            #expect(controller.wrapUpCardToShow(currentDate: insideWindowDate) == nil)

            controller.clearWrapUpCardSeen()
            #expect(controller.wrapUpCardToShow(currentDate: insideWindowDate) == .feedbackSurvey)

            WMFDeveloperSettingsDataController.shared.forceDonationReminderExperimentAssignment = nil
        }
    }

    @Test
    func overriddenCurrentDateControlsTheWrapUpWindow() async {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            WMFDeveloperSettingsDataController.shared.forceDonationReminderExperimentAssignment = .groupB

            WMFDeveloperSettingsDataController.shared.fundraisingOverriddenCurrentDate = WMFDonationReminderDataController.reminderEndDate.addingTimeInterval(-3_600)
            #expect(controller.wrapUpCardToShow() == nil)

            WMFDeveloperSettingsDataController.shared.fundraisingOverriddenCurrentDate = WMFDonationReminderDataController.reminderEndDate.addingTimeInterval(3_600)
            #expect(controller.wrapUpCardToShow() == .feedbackSurvey)

            WMFDeveloperSettingsDataController.shared.fundraisingOverriddenCurrentDate = nil
            WMFDeveloperSettingsDataController.shared.forceDonationReminderExperimentAssignment = nil
        }
    }

    @Test
    func notNowClosesTheWindowUntilTheNextGoal() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironmentWithCoreData) {
            let createdDate = Date(timeIntervalSince1970: 1_755_600_000)
            let nextDay = createdDate.addingTimeInterval(100_000)
            controller.saveReminder(WMFDonationReminder(trigger: .articlesRead(count: 1), amount: 3, currencyCode: "EUR", createdDate: createdDate, isEnabled: true))

            let firstShownDate = createdDate.addingTimeInterval(1_000)
            controller.recordFollowUpReminderShown(currentDate: firstShownDate)
            #expect(controller.isFollowUpReminderWindowClosed == false)
            controller.closeFollowUpReminderWindow()
            #expect(controller.isFollowUpReminderWindowClosed == true)

            let reminder = try #require(controller.loadReminder())
            #expect(reminder.timesReminderShown == 2)
            #expect(reminder.currentCycleStartDate == firstShownDate)

            #expect(try await controller.shouldShowFollowUpReminder(currentDate: nextDay) == false)

            try await addQualifyingPageView(title: "After_Not_Now", timestamp: nextDay.addingTimeInterval(100))
            #expect(try await controller.shouldShowFollowUpReminder(currentDate: nextDay.addingTimeInterval(1_000)) == true)
        }
    }

    @Test
    func goalReachedCountIncrementsOncePerWindow() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironmentWithCoreData) {
            let createdDate = Date(timeIntervalSince1970: 1_755_600_000)
            let secondDay = createdDate.addingTimeInterval(100_000)
            let thirdDay = createdDate.addingTimeInterval(200_000)
            controller.saveReminder(WMFDonationReminder(trigger: .articlesRead(count: 1), amount: 3, currencyCode: "EUR", createdDate: createdDate, isEnabled: true))

            controller.recordFollowUpReminderShown(currentDate: createdDate.addingTimeInterval(1_000))
            controller.recordFollowUpReminderShown(currentDate: secondDay)
            #expect(controller.loadReminder()?.goalReachedCount == 1)

            controller.recordFollowUpReminderShown(currentDate: thirdDay)
            #expect(controller.loadReminder()?.goalReachedCount == 2)
        }
    }

    @Test
    func claimRecordsTheImpressionAndReturnsTheUpdatedReminder() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironmentWithCoreData) {
            let createdDate = Date(timeIntervalSince1970: 1_755_600_000)
            controller.saveReminder(WMFDonationReminder(trigger: .articlesRead(count: 1), amount: 3, currencyCode: "EUR", createdDate: createdDate, isEnabled: true))

            try await addQualifyingPageView(title: "First", timestamp: createdDate.addingTimeInterval(100))

            let claimedDate = createdDate.addingTimeInterval(1_000)
            let claimedReminder = try #require(try await controller.claimFollowUpReminderImpression(currentDate: claimedDate))
            #expect(claimedReminder.timesReminderShown == 1)
            #expect(claimedReminder.goalReachedCount == 1)
            #expect(claimedReminder.currentCycleStartDate == claimedDate)
            #expect(controller.loadReminder() == claimedReminder)
        }
    }

    @Test
    func claimReturnsNilWhenAnImpressionWasAlreadyClaimedTheSameDay() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironmentWithCoreData) {
            let createdDate = Date(timeIntervalSince1970: 1_755_600_000)
            controller.saveReminder(WMFDonationReminder(trigger: .articlesRead(count: 1), amount: 3, currencyCode: "EUR", createdDate: createdDate, isEnabled: true))

            try await addQualifyingPageView(title: "First", timestamp: createdDate.addingTimeInterval(100))

            let claimedDate = createdDate.addingTimeInterval(1_000)
            let firstClaim = try await controller.claimFollowUpReminderImpression(currentDate: claimedDate)
            #expect(firstClaim != nil)

            let secondClaim = try await controller.claimFollowUpReminderImpression(currentDate: claimedDate.addingTimeInterval(100))
            #expect(secondClaim == nil)
            #expect(controller.loadReminder()?.timesReminderShown == 1)
        }
    }

    @Test
    func reminderPayloadWithoutProgressDecodesWithCreatedDateAsCycleStart() throws {
        let createdDate = Date(timeIntervalSince1970: 1_755_600_000)
        let reminderBeforeProgressExisted = WMFDonationReminder(trigger: .articlesRead(count: 5), amount: 3, currencyCode: "EUR", createdDate: createdDate, isEnabled: true)

        let legacyPayload = try JSONEncoder().encode(reminderBeforeProgressExisted)
        let legacyJSON = try #require(String(data: legacyPayload, encoding: .utf8))
        #expect(legacyJSON.contains("progress") == false)

        let reminder = try JSONDecoder().decode(WMFDonationReminder.self, from: legacyPayload)
        #expect(reminder.progress == nil)
        #expect(reminder.currentCycleStartDate == createdDate)
        #expect(reminder.timesReminderShown == 0)
        #expect(reminder.goalReachedCount == 0)
    }

    @Test
    func progressPayloadWithoutGoalReachedCountDecodesToZero() throws {
        let cycleStartDate = Date(timeIntervalSince1970: 1_755_600_000)
        let progress = WMFDonationReminder.Progress(currentCycleStartDate: cycleStartDate, timesReminderShown: 1, goalReachedCount: 7)
        let reminder = WMFDonationReminder(trigger: .articlesRead(count: 5), amount: 3, currencyCode: "EUR", createdDate: cycleStartDate, isEnabled: true, progress: progress)

        var reminderJSON = try #require(try JSONSerialization.jsonObject(with: JSONEncoder().encode(reminder)) as? [String: Any])
        var progressJSON = try #require(reminderJSON["progress"] as? [String: Any])
        progressJSON.removeValue(forKey: "goalReachedCount")
        reminderJSON["progress"] = progressJSON
        let legacyPayload = try JSONSerialization.data(withJSONObject: reminderJSON)

        let decodedReminder = try JSONDecoder().decode(WMFDonationReminder.self, from: legacyPayload)
        #expect(decodedReminder.goalReachedCount == 0)
        #expect(decodedReminder.timesReminderShown == 1)
        #expect(decodedReminder.progress?.currentCycleStartDate == cycleStartDate)
    }

    @Test
    func progressPayloadWithoutIsWindowClosedDecodesToFalse() throws {
        let cycleStartDate = Date(timeIntervalSince1970: 1_755_600_000)
        let progress = WMFDonationReminder.Progress(currentCycleStartDate: cycleStartDate, timesReminderShown: 2, isWindowClosed: true)
        let reminder = WMFDonationReminder(trigger: .articlesRead(count: 5), amount: 3, currencyCode: "EUR", createdDate: cycleStartDate, isEnabled: true, progress: progress)

        var reminderJSON = try #require(try JSONSerialization.jsonObject(with: JSONEncoder().encode(reminder)) as? [String: Any])
        var progressJSON = try #require(reminderJSON["progress"] as? [String: Any])
        progressJSON.removeValue(forKey: "isWindowClosed")
        reminderJSON["progress"] = progressJSON
        let legacyPayload = try JSONSerialization.data(withJSONObject: reminderJSON)

        let decodedReminder = try JSONDecoder().decode(WMFDonationReminder.self, from: legacyPayload)
        #expect(decodedReminder.progress?.isWindowClosed == false)
        #expect(decodedReminder.timesReminderShown == 2)
        #expect(decodedReminder.progress?.currentCycleStartDate == cycleStartDate)
    }

    @Test
    func experimentAssignmentIsNilBeforeAssignment() async {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            #expect(controller.experimentAssignment == nil)
        }
    }

    @Test
    func assignExperimentPersistsAssignment() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let assignment = try assignExperiment()

            #expect(controller.experimentAssignment == assignment)

            let repeatedAssignment = try assignExperiment()
            #expect(repeatedAssignment == assignment)
        }
    }

    @Test
    func assignExperimentReturnsNilForAnotherCampaign() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let assignment = try controller.assignExperimentIfNeeded(campaignID: "BR_2026_08", campaignCurrencyCode: "BRL")

            #expect(assignment == nil)
            #expect(controller.experimentAssignment == nil)
            #expect(controller.experimentCurrencyCode == nil)
        }
    }

    @Test
    func assignExperimentSavesTheCampaignCurrencyForTreatmentGroups() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            WMFDeveloperSettingsDataController.shared.forceDonationReminderExperimentAssignment = .groupB

            let assignment = try assignExperiment(campaignCurrencyCode: "EUR")

            #expect(assignment == .groupB)
            #expect(controller.experimentCurrencyCode == "EUR")

            WMFDeveloperSettingsDataController.shared.forceDonationReminderExperimentAssignment = nil
        }
    }

    @Test
    func assignExperimentDoesNotSaveTheCampaignCurrencyForControl() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            WMFDeveloperSettingsDataController.shared.forceDonationReminderExperimentAssignment = .control

            let assignment = try assignExperiment(campaignCurrencyCode: "EUR")

            #expect(assignment == .control)
            #expect(controller.experimentCurrencyCode == nil)

            WMFDeveloperSettingsDataController.shared.forceDonationReminderExperimentAssignment = nil
        }
    }

    @Test
    func forcedAssignmentBypassesTheCampaignGate() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            WMFDeveloperSettingsDataController.shared.forceDonationReminderExperimentAssignment = .groupC

            let assignment = try controller.assignExperimentIfNeeded(campaignID: "BR_2026_08", campaignCurrencyCode: "BRL")

            #expect(assignment == .groupC)
            #expect(controller.experimentCurrencyCode == "BRL")

            WMFDeveloperSettingsDataController.shared.forceDonationReminderExperimentAssignment = nil
        }
    }

    @Test
    func reminderSetupCurrencyPrefersThePledgeOverTheExperimentCurrency() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            WMFDeveloperSettingsDataController.shared.forceDonationReminderExperimentAssignment = .groupB
            try assignExperiment(campaignCurrencyCode: "EUR")
            WMFDeveloperSettingsDataController.shared.forceDonationReminderExperimentAssignment = nil

            #expect(controller.reminderSetupCurrencyCode == "EUR")

            controller.saveReminder(WMFDonationReminder(trigger: .articlesRead(count: 5), amount: 1, currencyCode: "USD", createdDate: Date(), isEnabled: true))

            #expect(controller.reminderSetupCurrencyCode == "USD")
        }
    }

    @Test
    func clearExperimentAssignmentClearsTheCampaignCurrency() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            WMFDeveloperSettingsDataController.shared.forceDonationReminderExperimentAssignment = .groupB
            try assignExperiment(campaignCurrencyCode: "EUR")
            WMFDeveloperSettingsDataController.shared.forceDonationReminderExperimentAssignment = nil
            #expect(controller.experimentCurrencyCode == "EUR")

            controller.clearExperimentAssignment()

            #expect(controller.experimentCurrencyCode == nil)
        }
    }

    @Test
    func assignExperimentProducesAllThreeGroups() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let experimentStore = try #require(WMFDataEnvironment.current.sharedCacheStore)
            let experimentsDataController = WMFExperimentsDataController(store: experimentStore)

            var seenAssignments = Set<WMFDonationReminderDataController.ExperimentAssignment>()
            for _ in 1...200 {
                try experimentsDataController.resetExperiment(.donationReminder)
                seenAssignments.insert(try assignExperiment())
                if seenAssignments.count == 3 {
                    break
                }
            }

            #expect(seenAssignments == [.control, .groupB, .groupC])
        }
    }

    @Test
    func clearExperimentAssignmentAllowsANewRoll() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try assignExperiment()
            #expect(controller.experimentAssignment != nil)

            controller.clearExperimentAssignment()

            #expect(controller.experimentAssignment == nil)
        }
    }

    @Test
    func clearFundraisingCampaignPersistenceClearsReminderAndAssignment() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let createdDate = Date(timeIntervalSince1970: 1_755_600_000)
            controller.saveReminder(WMFDonationReminder(trigger: .articlesRead(count: 5), amount: 3, currencyCode: "EUR", createdDate: createdDate, isEnabled: true))
            try assignExperiment()

            WMFDeveloperSettingsDataController.shared.clearFundraisingCampaignPersistence()

            #expect(controller.loadReminder() == nil)
            #expect(controller.experimentAssignment == nil)
            #expect(controller.experimentCurrencyCode == nil)
        }
    }

    @Test
    func developerSettingsForceOverridesAssignmentAtReadTimeOnly() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let persistedAssignment = try assignExperiment()

            WMFDeveloperSettingsDataController.shared.forceDonationReminderExperimentAssignment = .groupC
            #expect(controller.experimentAssignment == .groupC)
            #expect(try assignExperiment() == .groupC)

            WMFDeveloperSettingsDataController.shared.forceDonationReminderExperimentAssignment = .control
            #expect(controller.experimentAssignment == .control)

            WMFDeveloperSettingsDataController.shared.forceDonationReminderExperimentAssignment = nil
            #expect(controller.experimentAssignment == persistedAssignment)
        }
    }

    @Test
    func settingsEntryUnavailableForControlAssignment() async {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            WMFDeveloperSettingsDataController.shared.forceDonationReminderExperimentAssignment = .control
            controller.saveReminder(WMFDonationReminder(trigger: .articlesRead(count: 5), amount: 1, currencyCode: "EUR", createdDate: Date(), isEnabled: true))

            #expect(controller.isReminderSettingsEntryAvailable() == false)

            WMFDeveloperSettingsDataController.shared.forceDonationReminderExperimentAssignment = nil
        }
    }

    @Test
    func settingsEntryAvailableWithoutSavedReminder() async {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            WMFDeveloperSettingsDataController.shared.forceDonationReminderExperimentAssignment = .groupB

            #expect(controller.isReminderSettingsEntryAvailable())

            WMFDeveloperSettingsDataController.shared.forceDonationReminderExperimentAssignment = nil
        }
    }

    @Test
    func settingsEntryAvailableForTreatmentGroupWithSavedReminder() async {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            WMFDeveloperSettingsDataController.shared.forceDonationReminderExperimentAssignment = .groupB
            controller.saveReminder(WMFDonationReminder(trigger: .articlesRead(count: 5), amount: 1, currencyCode: "EUR", createdDate: Date(), isEnabled: true))

            #expect(controller.isReminderSettingsEntryAvailable())

            WMFDeveloperSettingsDataController.shared.forceDonationReminderExperimentAssignment = nil
        }
    }

    @Test
    func settingsEntryStopsAtReminderEndDate() async {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            WMFDeveloperSettingsDataController.shared.forceDonationReminderExperimentAssignment = .groupC
            controller.saveReminder(WMFDonationReminder(trigger: .articlesRead(count: 5), amount: 1, currencyCode: "EUR", createdDate: Date(timeIntervalSince1970: 1_700_000_000), isEnabled: true))

            let endDate = WMFDonationReminderDataController.reminderEndDate
            #expect(controller.isReminderSettingsEntryAvailable(currentDate: endDate.addingTimeInterval(-86_400)))
            #expect(controller.isReminderSettingsEntryAvailable(currentDate: endDate) == false)

            WMFDeveloperSettingsDataController.shared.forceDonationReminderExperimentAssignment = nil
        }
    }

    @Test
    func followUpReminderStopsAtReminderEndDate() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironmentWithCoreData) {
            let endDate = WMFDonationReminderDataController.reminderEndDate
            let progress = WMFDonationReminder.Progress(currentCycleStartDate: endDate.addingTimeInterval(-172_800), timesReminderShown: 1)
            controller.saveReminder(WMFDonationReminder(trigger: .articlesRead(count: 5), amount: 1, currencyCode: "EUR", createdDate: endDate.addingTimeInterval(-864_000), isEnabled: true, progress: progress))

            let showsBeforeEndDate = try await controller.shouldShowFollowUpReminder(currentDate: endDate.addingTimeInterval(-86_400))
            let showsAtEndDate = try await controller.shouldShowFollowUpReminder(currentDate: endDate)
            #expect(showsBeforeEndDate)
            #expect(showsAtEndDate == false)
        }
    }

    @discardableResult
    private func assignExperiment(campaignID: String = WMFDonationReminderDataController.experimentCampaignID, campaignCurrencyCode: String = "EUR") throws -> WMFDonationReminderDataController.ExperimentAssignment {
        try #require(try controller.assignExperimentIfNeeded(campaignID: campaignID, campaignCurrencyCode: campaignCurrencyCode))
    }

    @Test
    func overriddenCurrentDateWinsTheReminderEndGate() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            WMFDeveloperSettingsDataController.shared.forceDonationReminderExperimentAssignment = .groupB
            let progress = WMFDonationReminder.Progress(currentCycleStartDate: Date(timeIntervalSince1970: 1_755_600_000), timesReminderShown: 1)
            controller.saveReminder(WMFDonationReminder(trigger: .articlesRead(count: 5), amount: 1, currencyCode: "EUR", createdDate: Date(timeIntervalSince1970: 1_700_000_000), isEnabled: true, progress: progress))
            let beforeEndDate = WMFDonationReminderDataController.reminderEndDate.addingTimeInterval(-86_400)

            let showsWithoutOverride = try await controller.shouldShowFollowUpReminder(currentDate: beforeEndDate)
            #expect(controller.isReminderSettingsEntryAvailable(currentDate: beforeEndDate))
            #expect(showsWithoutOverride)

            WMFDeveloperSettingsDataController.shared.fundraisingOverriddenCurrentDate = WMFDonationReminderDataController.reminderEndDate
            let showsWithOverride = try await controller.shouldShowFollowUpReminder(currentDate: beforeEndDate)
            #expect(controller.isReminderSettingsEntryAvailable(currentDate: beforeEndDate) == false)
            #expect(showsWithOverride == false)

            WMFDeveloperSettingsDataController.shared.fundraisingOverriddenCurrentDate = nil
            WMFDeveloperSettingsDataController.shared.forceDonationReminderExperimentAssignment = nil
        }
    }

    private func addQualifyingPageView(title: String, timestamp: Date) async throws {
        try await addPageView(title: title, timestamp: timestamp, numberOfSeconds: Double(WMFDonationReminderDataController.minimumSecondsForArticleRead))
    }

    private func addPageView(title: String, timestamp: Date, numberOfSeconds: Double) async throws {
        let project = WMFProject.wikipedia(WMFLanguage(languageCode: "nl", languageVariantCode: nil))
        let pageViewsDataController = try WMFPageViewsDataController()
        let pageViewManagedObjectID = try await pageViewsDataController.addPageView(title: title, namespaceID: 0, project: project, previousPageViewObjectID: nil, timestamp: timestamp)
        if numberOfSeconds > 0, let pageViewManagedObjectID {
            try await pageViewsDataController.addPageViewSeconds(pageViewManagedObjectID: pageViewManagedObjectID, numberOfSeconds: numberOfSeconds)
        }
    }

    @Test
    func completedDonationClosesFollowUpReminderWindow() async {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let progress = WMFDonationReminder.Progress(currentCycleStartDate: Date(), timesReminderShown: 1, lastReminderShownDate: Date())
            controller.saveReminder(WMFDonationReminder(trigger: .articlesRead(count: 5), amount: 1, currencyCode: "EUR", createdDate: Date(), isEnabled: true, progress: progress))
            #expect(controller.isFollowUpReminderWindowClosed == false)

            let donateDataController = WMFDonateDataController(service: nil, sharedCacheStore: WMFMockKeyValueStore())
            _ = donateDataController.saveLocalDonationHistory(type: .oneTime, amount: 1, currencyCode: "EUR", isNative: true)

            #expect(controller.isFollowUpReminderWindowClosed)
        }
    }

    private func configureEnvironment() async {
        WMFDataEnvironment.current.userDefaultsStore = WMFMockKeyValueStore()
        WMFDataEnvironment.current.sharedCacheStore = WMFMockKeyValueStore()
    }

    private func configureEnvironmentWithCoreData() async throws {
        WMFDataEnvironment.current.userDefaultsStore = WMFMockKeyValueStore()
        WMFDataEnvironment.current.coreDataStore = try await fixture.makeTemporaryCoreDataStore()
    }
}

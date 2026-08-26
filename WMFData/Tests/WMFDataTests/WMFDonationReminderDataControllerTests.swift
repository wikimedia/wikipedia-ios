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
    func experimentAssignmentIsNilBeforeAssignment() async {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            #expect(controller.experimentAssignment == nil)
        }
    }

    @Test
    func assignExperimentPersistsAssignment() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let assignment = try controller.assignExperimentIfNeeded()

            #expect(controller.experimentAssignment == assignment)

            let repeatedAssignment = try controller.assignExperimentIfNeeded()
            #expect(repeatedAssignment == assignment)
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
                seenAssignments.insert(try controller.assignExperimentIfNeeded())
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
            try controller.assignExperimentIfNeeded()
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
            try controller.assignExperimentIfNeeded()

            WMFDeveloperSettingsDataController.shared.clearFundraisingCampaignPersistence()

            #expect(controller.loadReminder() == nil)
            #expect(controller.experimentAssignment == nil)
        }
    }

    @Test
    func developerSettingsForceOverridesAssignmentAtReadTimeOnly() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let persistedAssignment = try controller.assignExperimentIfNeeded()

            WMFDeveloperSettingsDataController.shared.forceDonationReminderExperimentAssignment = .groupC
            #expect(controller.experimentAssignment == .groupC)
            #expect(try controller.assignExperimentIfNeeded() == .groupC)

            WMFDeveloperSettingsDataController.shared.forceDonationReminderExperimentAssignment = .control
            #expect(controller.experimentAssignment == .control)

            WMFDeveloperSettingsDataController.shared.forceDonationReminderExperimentAssignment = nil
            #expect(controller.experimentAssignment == persistedAssignment)
        }
    }

    @Test
    func settingsEntryUnavailableWhenFeatureFlagIsOff() async {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            WMFDeveloperSettingsDataController.shared.forceDonationReminderExperimentAssignment = .groupB
            controller.saveReminder(WMFDonationReminder(trigger: .articlesRead(count: 5), amount: 1, currencyCode: "EUR", createdDate: Date(), isEnabled: true))

            #expect(controller.isReminderSettingsEntryAvailable() == false)

            WMFDeveloperSettingsDataController.shared.forceDonationReminderExperimentAssignment = nil
        }
    }

    @Test
    func settingsEntryUnavailableForControlAssignment() async {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            WMFDeveloperSettingsDataController.shared.enableDonationReminder = true
            WMFDeveloperSettingsDataController.shared.forceDonationReminderExperimentAssignment = .control
            controller.saveReminder(WMFDonationReminder(trigger: .articlesRead(count: 5), amount: 1, currencyCode: "EUR", createdDate: Date(), isEnabled: true))

            #expect(controller.isReminderSettingsEntryAvailable() == false)

            WMFDeveloperSettingsDataController.shared.forceDonationReminderExperimentAssignment = nil
        }
    }

    @Test
    func settingsEntryUnavailableWithoutSavedReminder() async {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            WMFDeveloperSettingsDataController.shared.enableDonationReminder = true
            WMFDeveloperSettingsDataController.shared.forceDonationReminderExperimentAssignment = .groupB

            #expect(controller.isReminderSettingsEntryAvailable() == false)

            WMFDeveloperSettingsDataController.shared.forceDonationReminderExperimentAssignment = nil
        }
    }

    @Test
    func settingsEntryAvailableForTreatmentGroupWithSavedReminder() async {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            WMFDeveloperSettingsDataController.shared.enableDonationReminder = true
            WMFDeveloperSettingsDataController.shared.forceDonationReminderExperimentAssignment = .groupB
            controller.saveReminder(WMFDonationReminder(trigger: .articlesRead(count: 5), amount: 1, currencyCode: "EUR", createdDate: Date(), isEnabled: true))

            #expect(controller.isReminderSettingsEntryAvailable())

            WMFDeveloperSettingsDataController.shared.forceDonationReminderExperimentAssignment = nil
        }
    }

    @Test
    func settingsEntryFollowsExperimentEndDate() async {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            WMFDeveloperSettingsDataController.shared.enableDonationReminder = true
            WMFDeveloperSettingsDataController.shared.forceDonationReminderExperimentAssignment = .groupC
            let endDate = Date(timeIntervalSince1970: 1_800_000_000)
            controller.saveReminder(WMFDonationReminder(trigger: .articlesRead(count: 5), amount: 1, currencyCode: "EUR", createdDate: Date(timeIntervalSince1970: 1_700_000_000), isEnabled: true, experimentEndDate: endDate))

            #expect(controller.isReminderSettingsEntryAvailable(currentDate: endDate.addingTimeInterval(-86_400)))
            #expect(controller.isReminderSettingsEntryAvailable(currentDate: endDate.addingTimeInterval(86_400)) == false)

            WMFDeveloperSettingsDataController.shared.forceDonationReminderExperimentAssignment = nil
        }
    }

    @Test
    func reminderExpiryFollowsExperimentEndDate() async {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let endDate = Date(timeIntervalSince1970: 1_800_000_000)
            let reminder = WMFDonationReminder(trigger: .articlesRead(count: 5), amount: 1, currencyCode: "EUR", createdDate: Date(timeIntervalSince1970: 1_700_000_000), isEnabled: true, experimentEndDate: endDate)

            #expect(reminder.isExpired(currentDate: endDate.addingTimeInterval(-86_400)) == false)
            #expect(reminder.isExpired(currentDate: endDate.addingTimeInterval(86_400)))
        }
    }

    @Test
    func reminderWithoutEndDateNeverExpires() async {
        await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let reminder = WMFDonationReminder(trigger: .articlesRead(count: 5), amount: 1, currencyCode: "EUR", createdDate: Date(), isEnabled: true)

            #expect(reminder.isExpired(currentDate: .distantFuture) == false)
        }
    }

    @Test
    func experimentEndDateSurvivesSaveAndLoad() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let endDate = Date(timeIntervalSince1970: 1_800_000_000)
            controller.saveReminder(WMFDonationReminder(trigger: .articlesRead(count: 5), amount: 1, currencyCode: "EUR", createdDate: Date(), isEnabled: true, experimentEndDate: endDate))

            let loadedReminder = try #require(controller.loadReminder())
            #expect(loadedReminder.experimentEndDate == endDate)
        }
    }

    private func configureEnvironment() async {
        WMFDataEnvironment.current.userDefaultsStore = WMFMockKeyValueStore()
        WMFDataEnvironment.current.sharedCacheStore = WMFMockKeyValueStore()
    }
}

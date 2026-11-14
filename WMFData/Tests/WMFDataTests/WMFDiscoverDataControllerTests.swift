import Foundation
import Testing
import WMFDataTestSupport
@testable import WMFData
@testable import WMFDataMocks

@Suite(.serialized)
final class WMFDiscoverDataControllerTests {

    private let fixture = WMFDataTestFixture()
    private let controller = WMFDiscoverDataController.shared

    @Test
    func announcementStaysHiddenWhileTheDeveloperToggleIsOff() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            WMFDeveloperSettingsDataController.shared.forceDiscoverExperimentAssignment = .groupB

            #expect(controller.isEnabled == false)
            #expect(controller.shouldShowAnnouncement == false)
        }
    }

    @Test
    func remoteFlagTurnsDiscoverOn() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try saveRemoteConfig(discoverExperimentEnabled: true)

            #expect(controller.isEnabled)
        }
    }

    @Test
    func remoteFlagOffKeepsDiscoverOff() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try saveRemoteConfig(discoverExperimentEnabled: false)

            #expect(controller.isEnabled == false)
        }
    }

    @Test
    func remoteConfigWithoutTheFlagKeepsDiscoverOff() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try saveRemoteConfig(discoverExperimentControlPercentage: 50)

            #expect(controller.isEnabled == false)
        }
    }

    @Test
    func developerToggleForcesDiscoverOnOverTheRemoteFlag() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try saveRemoteConfig(discoverExperimentEnabled: false)
            WMFDeveloperSettingsDataController.shared.enableDiscover = true

            #expect(controller.isEnabled)
        }
    }

    @Test
    func announcementFollowsTheGroupBAssignment() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            WMFDeveloperSettingsDataController.shared.enableDiscover = true

            #expect(controller.shouldShowAnnouncement == false)

            WMFDeveloperSettingsDataController.shared.forceDiscoverExperimentAssignment = .control
            #expect(controller.shouldShowAnnouncement == false)

            WMFDeveloperSettingsDataController.shared.forceDiscoverExperimentAssignment = .groupB
            #expect(controller.shouldShowAnnouncement)
        }
    }

    @Test
    func turningDiscoverOnHidesTheAnnouncementWithoutDismissingIt() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            WMFDeveloperSettingsDataController.shared.enableDiscover = true
            WMFDeveloperSettingsDataController.shared.forceDiscoverExperimentAssignment = .groupB

            #expect(controller.shouldShowAnnouncement)

            var settings = await WMFDiscoverReadingListDataController.shared.settings
            settings.isEnabled = true
            try await WMFDiscoverReadingListDataController.shared.saveSettings(settings)

            #expect(controller.hasDismissedAnnouncement == false)
            #expect(controller.shouldShowAnnouncement == false)
        }
    }

    @Test
    func discoverStaysHiddenWhileTheFeatureIsOff() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            WMFDeveloperSettingsDataController.shared.forceDiscoverExperimentAssignment = .groupB

            #expect(controller.isAvailableToReader == false)
        }
    }

    @Test
    func discoverIsAvailableOnlyToGroupB() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try saveRemoteConfig(discoverExperimentEnabled: true)

            #expect(controller.isAvailableToReader == false, "A reader without a group does not see Discover")

            WMFDeveloperSettingsDataController.shared.forceDiscoverExperimentAssignment = .control
            #expect(controller.isAvailableToReader == false, "The control group does not see Discover")

            WMFDeveloperSettingsDataController.shared.forceDiscoverExperimentAssignment = .groupB
            #expect(controller.isAvailableToReader)
        }
    }

    @Test
    func controlGroupSeesNoBadgeEvenWithDiscoverTurnedOn() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try saveRemoteConfig(discoverExperimentEnabled: true)
            WMFDeveloperSettingsDataController.shared.forceDiscoverExperimentAssignment = .control

            var settings = await WMFDiscoverReadingListDataController.shared.settings
            settings.isEnabled = true
            try await WMFDiscoverReadingListDataController.shared.saveSettings(settings)
            let userDefaultsStore = try #require(WMFDataEnvironment.current.userDefaultsStore)
            try userDefaultsStore.save(key: WMFUserDefaultsKey.discoverHasUnseenList.rawValue, value: true)

            #expect(controller.isAvailableToReader == false)
            #expect(controller.shouldShowUnseenListBadge == false)

            WMFDeveloperSettingsDataController.shared.forceDiscoverExperimentAssignment = .groupB
            #expect(controller.shouldShowUnseenListBadge)
        }
    }

    @Test
    func onlyTheControlGroupWithDiscoverOnNeedsTheTurnOff() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try saveRemoteConfig(discoverExperimentEnabled: true)
            WMFDeveloperSettingsDataController.shared.forceDiscoverExperimentAssignment = .control
            #expect(controller.hasListTurnedOnInControlGroup == false, "Discover off needs no turn off")

            var settings = await WMFDiscoverReadingListDataController.shared.settings
            settings.isEnabled = true
            try await WMFDiscoverReadingListDataController.shared.saveSettings(settings)
            #expect(controller.hasListTurnedOnInControlGroup)

            WMFDeveloperSettingsDataController.shared.forceDiscoverExperimentAssignment = .groupB
            #expect(controller.hasListTurnedOnInControlGroup == false, "Group B keeps the list")

            WMFDeveloperSettingsDataController.shared.forceDiscoverExperimentAssignment = nil
            #expect(controller.hasListTurnedOnInControlGroup == false, "A reader without a group keeps the settings")
        }
    }

    // The feature config is cached in memory after its first read, so this case has its own test.
    @Test
    func theFeatureOffNeedsNoTurnOff() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try saveRemoteConfig(discoverExperimentEnabled: false)
            WMFDeveloperSettingsDataController.shared.forceDiscoverExperimentAssignment = .control

            var settings = await WMFDiscoverReadingListDataController.shared.settings
            settings.isEnabled = true
            try await WMFDiscoverReadingListDataController.shared.saveSettings(settings)

            #expect(controller.hasListTurnedOnInControlGroup == false)
        }
    }

    @Test
    func dismissingTheAnnouncementIsPermanent() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            WMFDeveloperSettingsDataController.shared.enableDiscover = true
            WMFDeveloperSettingsDataController.shared.forceDiscoverExperimentAssignment = .groupB

            #expect(controller.hasDismissedAnnouncement == false)
            #expect(controller.shouldShowAnnouncement)

            try controller.markAnnouncementDismissed()

            #expect(controller.hasDismissedAnnouncement)
            #expect(controller.shouldShowAnnouncement == false)

            try controller.resetAnnouncement()

            #expect(controller.shouldShowAnnouncement)
        }
    }

    @Test
    func assignmentRollsOnceAndKeepsTheBucket() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            #expect(controller.experimentAssignment == nil)

            let firstAssignment = try controller.assignExperimentIfNeeded()
            let secondAssignment = try controller.assignExperimentIfNeeded()

            #expect(secondAssignment == firstAssignment)
            #expect(controller.experimentAssignment == firstAssignment)
        }
    }

    @Test
    func bucketRollFollowsTheControlPercentage() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let store = try #require(WMFDataEnvironment.current.sharedCacheStore)
            let experimentsDataController = WMFExperimentsDataController(store: store)

            let controlBucket = try experimentsDataController.determineBucketForExperiment(.discover, withPercentage: 50, randomIntProvider: { 50 })
            try experimentsDataController.resetExperiment(.discover)
            let groupBBucket = try experimentsDataController.determineBucketForExperiment(.discover, withPercentage: 50, randomIntProvider: { 51 })

            #expect(controlBucket == .discoverControl)
            #expect(groupBBucket == .discoverGroupB)
        }
    }

    @Test
    func forcedAssignmentOverridesTheBucketAtReadTime() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let store = try #require(WMFDataEnvironment.current.sharedCacheStore)
            let experimentsDataController = WMFExperimentsDataController(store: store)
            _ = try experimentsDataController.determineBucketForExperiment(.discover, withPercentage: 50, randomIntProvider: { 1 })
            #expect(controller.experimentAssignment == .control)

            WMFDeveloperSettingsDataController.shared.forceDiscoverExperimentAssignment = .groupB
            #expect(controller.experimentAssignment == .groupB)
            #expect(try controller.assignExperimentIfNeeded() == .groupB)

            WMFDeveloperSettingsDataController.shared.forceDiscoverExperimentAssignment = nil
            #expect(controller.experimentAssignment == .control)
        }
    }

    @Test
    func clearingTheAssignmentAllowsANewRoll() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            _ = try controller.assignExperimentIfNeeded()
            #expect(controller.experimentAssignment != nil)

            try controller.clearExperimentAssignment()

            #expect(controller.experimentAssignment == nil)
        }
    }

    @Test
    func withoutTheRemoteKeyEveryoneIsInTheControlGroup() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            #expect(controller.experimentControlPercentage == 100)

            WMFDeveloperSettingsDataController.shared.enableDiscover = true
            let assignment = try controller.assignExperimentIfNeeded()
            #expect(assignment == .control)
            #expect(controller.shouldShowAnnouncement == false)
        }
    }

    @Test
    func controlPercentageComesFromTheRemoteFeatureConfig() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try saveRemoteControlPercentage(100)
            #expect(controller.experimentControlPercentage == 100)
        }
    }

    @Test
    func controlPercentageAcceptsZeroFromTheRemoteFeatureConfig() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try saveRemoteControlPercentage(0)
            #expect(controller.experimentControlPercentage == 0)
        }
    }

    @Test
    func controlPercentageOutsideTheRangeFallsBackToTheDefault() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try saveRemoteControlPercentage(140)
            #expect(controller.experimentControlPercentage == WMFDiscoverDataController.defaultExperimentControlPercentage)
        }
    }

    @Test
    func featureConfigDecodesWithoutTheDiscoverKey() throws {
        let json = Data("""
        {"commonv1": {"yir": []}, "iosv1": {"visualEditorEnabled": true}}
        """.utf8)

        let config = try JSONDecoder().decode(WMFFeatureConfigResponse.self, from: json)

        #expect(config.ios.discoverExperimentEnabled == nil)
        #expect(config.ios.discoverExperimentControlPercentage == nil)
    }

    @Test
    func featureConfigDecodesTheDiscoverKeys() throws {
        let json = Data("""
        {"commonv1": {"yir": []}, "iosv1": {"discoverExperimentEnabled": true, "discoverExperimentControlPercentage": 50}}
        """.utf8)

        let config = try JSONDecoder().decode(WMFFeatureConfigResponse.self, from: json)

        #expect(config.ios.discoverExperimentEnabled == true)
        #expect(config.ios.discoverExperimentControlPercentage == 50)
    }

    private func saveRemoteControlPercentage(_ percentage: Int) throws {
        try saveRemoteConfig(discoverExperimentControlPercentage: percentage)
    }

    private func saveRemoteConfig(discoverExperimentEnabled: Bool? = nil, discoverExperimentControlPercentage: Int? = nil) throws {
        let sharedCacheStore = try #require(WMFDataEnvironment.current.sharedCacheStore)
        let ios = WMFFeatureConfigResponse.IOS(hCaptcha: nil, discoverExperimentEnabled: discoverExperimentEnabled, discoverExperimentControlPercentage: discoverExperimentControlPercentage)
        let config = WMFFeatureConfigResponse(common: WMFFeatureConfigResponse.Common(yir: []), ios: ios, cachedDate: Date())
        try sharedCacheStore.save(key: "Developer Settings", "AppsFeatureConfig", value: config)
    }

    private func configureEnvironment() async {
        WMFDataEnvironment.current.userDefaultsStore = WMFMockKeyValueStore()
        WMFDataEnvironment.current.sharedCacheStore = WMFMockKeyValueStore()
    }
}

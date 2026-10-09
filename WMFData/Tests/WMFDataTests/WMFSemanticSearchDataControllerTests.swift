import Foundation
import Testing
import WMFDataTestSupport
@testable import WMFData
@testable import WMFDataMocks

@Suite(.serialized)
final class WMFSemanticSearchDataControllerTests {

    private let fixture = WMFDataTestFixture()
    private let controller = WMFSemanticSearchDataController.shared

    @Test
    func entryPointIsHiddenWhileTheDeveloperToggleIsOff() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            WMFDeveloperSettingsDataController.shared.forceSemanticSearchExperimentAssignment = .groupB

            #expect(controller.isEligible(languageCode: "fr") == false)
            #expect(controller.isEntryPointAvailable(languageCode: "fr") == false)
            let assignment = try controller.enrollIfNeeded(languageCode: "fr")
            #expect(assignment == nil)
        }
    }

    @Test
    func hiddenEntryPointDoesNotRenderUntilItIsShownAgain() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            WMFDeveloperSettingsDataController.shared.enableSemanticSearch = true
            WMFDeveloperSettingsDataController.shared.forceSemanticSearchExperimentAssignment = .groupB

            #expect(controller.isEntryPointHidden == false)
            #expect(controller.isEntryPointAvailable(languageCode: "fr"))

            try controller.setEntryPointHidden(true)

            #expect(controller.isEntryPointHidden)
            #expect(controller.isEntryPointAvailable(languageCode: "fr") == false)
            #expect(controller.isEligible(languageCode: "fr"))

            try controller.setEntryPointHidden(false)

            #expect(controller.isEntryPointAvailable(languageCode: "fr"))
        }
    }

    @Test
    func settingsEntryFollowsTheGroupBAssignment() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            #expect(controller.isSettingsEntryAvailable == false)

            WMFDeveloperSettingsDataController.shared.enableSemanticSearch = true
            WMFDeveloperSettingsDataController.shared.forceSemanticSearchExperimentAssignment = .control

            #expect(controller.isSettingsEntryAvailable == false)

            WMFDeveloperSettingsDataController.shared.forceSemanticSearchExperimentAssignment = .groupB

            #expect(controller.isSettingsEntryAvailable)

            try controller.setEntryPointHidden(true)

            #expect(controller.isSettingsEntryAvailable, "The hidden entry point keeps the Settings control that restores it")

            WMFDeveloperSettingsDataController.shared.enableSemanticSearch = false

            #expect(controller.isSettingsEntryAvailable == false)
        }
    }

    @Test
    func entryPointUseIsRemembered() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            #expect(controller.hasUsedEntryPoint == false)

            try controller.markEntryPointUsed()

            #expect(controller.hasUsedEntryPoint)

            try controller.setEntryPointHidden(true)
            try controller.resetEntryPointState()

            #expect(controller.hasUsedEntryPoint == false)
            #expect(controller.isEntryPointHidden == false)
        }
    }

    @Test
    func defaultTargetLanguagesApplyWithoutRemoteTargetLanguages() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            WMFDeveloperSettingsDataController.shared.enableSemanticSearch = true

            #expect(controller.targetLanguageCodes == WMFSemanticSearchDataController.defaultTargetLanguageCodes)
            #expect(controller.isEligible(languageCode: "fr"))
            #expect(controller.isEligible(languageCode: "en") == false)

            try saveRemoteTargetLanguages([])

            #expect(controller.targetLanguageCodes == WMFSemanticSearchDataController.defaultTargetLanguageCodes)
        }
    }

    @Test
    func searchesOutsideTheTargetLanguagesDoNotEnroll() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            WMFDeveloperSettingsDataController.shared.enableSemanticSearch = true
            try saveRemoteTargetLanguages(["fr", "ar", "ja"])

            #expect(controller.isEligible(languageCode: "en") == false)
            let assignment = try controller.enrollIfNeeded(languageCode: "en")
            #expect(assignment == nil)
            #expect(controller.experimentAssignment == nil)
            #expect(controller.isEntryPointAvailable(languageCode: "en") == false)
        }
    }

    @Test
    func experimentDataMatchesTheAndroidShape() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            WMFDeveloperSettingsDataController.shared.enableSemanticSearch = true
            try saveRemoteTargetLanguages(["fr", "ar", "ja"])
            WMFDataEnvironment.current.appInstallIDUtility = { "install-1" }

            #expect(controller.experimentData == nil)

            let enrollment = try #require(try controller.enrollIfNeeded(languageCode: "fr"))
            let data = try #require(controller.experimentData)

            #expect(data.enrolled == "semantic-search-phase-2")
            #expect(data.assigned == (enrollment.assignment == .groupB ? "treatment" : "control"))
            #expect(data.coordinator == "custom")
            #expect(data.subjectId == "install-1")

            WMFDeveloperSettingsDataController.shared.forceSemanticSearchExperimentAssignment = .groupB

            #expect(controller.experimentData?.assigned == "treatment")
            #expect(controller.experimentData?.coordinator == "forced")
        }
    }

    @Test
    func enrollmentIsNewOnlyTheFirstTime() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            WMFDeveloperSettingsDataController.shared.enableSemanticSearch = true
            try saveRemoteTargetLanguages(["fr", "ar", "ja"])

            #expect(try controller.enrollIfNeeded(languageCode: "en") == nil)

            let first = try #require(try controller.enrollIfNeeded(languageCode: "fr"))
            let second = try #require(try controller.enrollIfNeeded(languageCode: "ja"))

            #expect(first.isNew)
            #expect(second.isNew == false)
            #expect(second.assignment == first.assignment)
        }
    }

    @Test
    func targetLanguageSearchEnrollsOnceAndKeepsTheBucket() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            WMFDeveloperSettingsDataController.shared.enableSemanticSearch = true
            try saveRemoteTargetLanguages(["fr", "ar", "ja"])

            for languageCode in ["fr", "ar", "ja"] {
                #expect(controller.isEligible(languageCode: languageCode))
            }

            let firstAssignment = try #require(try controller.enrollIfNeeded(languageCode: "fr")).assignment
            let secondAssignment = try #require(try controller.enrollIfNeeded(languageCode: "ar")).assignment

            #expect(secondAssignment == firstAssignment)
            #expect(controller.experimentAssignment == firstAssignment)
            #expect(controller.isEntryPointAvailable(languageCode: "fr") == (firstAssignment == .groupB))
            #expect(controller.isEntryPointAvailable(languageCode: "en") == false)
        }
    }

    @Test
    func bucketRollFollowsTheControlPercentage() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let store = try #require(WMFDataEnvironment.current.sharedCacheStore)
            let experimentsDataController = WMFExperimentsDataController(store: store)

            let controlBucket = try experimentsDataController.determineBucketForExperiment(.semanticSearch, withPercentage: 50, randomIntProvider: { 50 })
            try experimentsDataController.resetExperiment(.semanticSearch)
            let groupBBucket = try experimentsDataController.determineBucketForExperiment(.semanticSearch, withPercentage: 50, randomIntProvider: { 51 })

            #expect(controlBucket == .semanticSearchControl)
            #expect(groupBBucket == .semanticSearchGroupB)
        }
    }

    @Test
    func forcedAssignmentOverridesTheBucketButKeepsTheLanguageGate() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            WMFDeveloperSettingsDataController.shared.enableSemanticSearch = true
            try saveRemoteTargetLanguages(["fr"])
            let store = try #require(WMFDataEnvironment.current.sharedCacheStore)
            let experimentsDataController = WMFExperimentsDataController(store: store)
            _ = try experimentsDataController.determineBucketForExperiment(.semanticSearch, withPercentage: 50, randomIntProvider: { 1 })
            #expect(controller.experimentAssignment == .control)

            WMFDeveloperSettingsDataController.shared.forceSemanticSearchExperimentAssignment = .groupB

            #expect(controller.experimentAssignment == .groupB)
            #expect(controller.isEligible(languageCode: "fr"))
            #expect(controller.isEntryPointAvailable(languageCode: "fr"))
            let forcedAssignment = try controller.enrollIfNeeded(languageCode: "fr")?.assignment
            #expect(forcedAssignment == .groupB)
            #expect(controller.isEligible(languageCode: "en") == false)
            #expect(controller.isEntryPointAvailable(languageCode: "en") == false)
            #expect(try controller.enrollIfNeeded(languageCode: "en") == nil)

            WMFDeveloperSettingsDataController.shared.forceSemanticSearchExperimentAssignment = nil

            #expect(controller.experimentAssignment == .control)
            #expect(controller.isEntryPointAvailable(languageCode: "fr") == false)
        }
    }

    @Test
    func clearingTheAssignmentAllowsANewRoll() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            WMFDeveloperSettingsDataController.shared.enableSemanticSearch = true
            try saveRemoteTargetLanguages(["ja"])
            _ = try controller.enrollIfNeeded(languageCode: "ja")
            #expect(controller.experimentAssignment != nil)

            try controller.clearExperimentAssignment()

            #expect(controller.experimentAssignment == nil)
            #expect(controller.isEntryPointAvailable(languageCode: "ja") == false)
        }
    }

    @Test
    func remoteFeatureConfigProvidesTheTargetLanguages() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try saveRemoteTargetLanguages(["en", "pt"])

            #expect(controller.targetLanguageCodes == ["en", "pt"])
            #expect(controller.isTargetLanguage(languageCode: "pt"))
            #expect(controller.isTargetLanguage(languageCode: "fr") == false)
        }
    }

    @Test
    func featureConfigDecodesWithoutTheSemanticSearchKey() throws {
        let json = Data("""
        {"commonv1": {"yir": []}, "iosv1": {"visualEditorEnabled": true}}
        """.utf8)

        let config = try JSONDecoder().decode(WMFFeatureConfigResponse.self, from: json)

        #expect(config.ios.semanticSearchLanguages.isEmpty)
        #expect(config.ios.visualEditorEnabled == true)
        #expect(config.ios.hCaptcha == nil)
    }

    @Test
    func featureConfigDecodesTheSemanticSearchLanguages() throws {
        let json = Data("""
        {"commonv1": {"yir": []}, "iosv1": {"semanticSearchLanguages": ["fr", "ar", "ja"]}}
        """.utf8)

        let config = try JSONDecoder().decode(WMFFeatureConfigResponse.self, from: json)

        #expect(config.ios.semanticSearchLanguages == ["fr", "ar", "ja"])
    }

    private func saveRemoteTargetLanguages(_ languageCodes: [String]) throws {
        let sharedCacheStore = try #require(WMFDataEnvironment.current.sharedCacheStore)
        let ios = WMFFeatureConfigResponse.IOS(hCaptcha: nil, semanticSearchLanguages: languageCodes)
        let config = WMFFeatureConfigResponse(common: WMFFeatureConfigResponse.Common(yir: []), ios: ios, cachedDate: Date())
        try sharedCacheStore.save(key: "Developer Settings", "AppsFeatureConfig", value: config)
    }

    private func configureEnvironment() async {
        WMFDataEnvironment.current.userDefaultsStore = WMFMockKeyValueStore()
        WMFDataEnvironment.current.sharedCacheStore = WMFMockKeyValueStore()
    }
}

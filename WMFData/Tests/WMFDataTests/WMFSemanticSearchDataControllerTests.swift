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
            let assignment = try controller.assignExperimentIfNeeded(languageCode: "fr")
            #expect(assignment == nil)
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
            let assignment = try controller.assignExperimentIfNeeded(languageCode: "en")
            #expect(assignment == nil)
            #expect(controller.experimentAssignment == nil)
            #expect(controller.isEntryPointAvailable(languageCode: "en") == false)
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

            let firstAssignment = try #require(try controller.assignExperimentIfNeeded(languageCode: "fr"))
            let secondAssignment = try #require(try controller.assignExperimentIfNeeded(languageCode: "ar"))

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
    func forcedAssignmentBypassesTheLanguageGateAndOverridesTheBucket() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            WMFDeveloperSettingsDataController.shared.enableSemanticSearch = true
            try saveRemoteTargetLanguages(["fr"])
            let store = try #require(WMFDataEnvironment.current.sharedCacheStore)
            let experimentsDataController = WMFExperimentsDataController(store: store)
            _ = try experimentsDataController.determineBucketForExperiment(.semanticSearch, withPercentage: 50, randomIntProvider: { 1 })
            #expect(controller.experimentAssignment == .control)

            WMFDeveloperSettingsDataController.shared.forceSemanticSearchExperimentAssignment = .groupB

            #expect(controller.isEligible(languageCode: "en"))
            #expect(controller.experimentAssignment == .groupB)
            #expect(controller.isEntryPointAvailable(languageCode: "en"))
            let forcedAssignment = try controller.assignExperimentIfNeeded(languageCode: "en")
            #expect(forcedAssignment == .groupB)

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
            _ = try controller.assignExperimentIfNeeded(languageCode: "ja")
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

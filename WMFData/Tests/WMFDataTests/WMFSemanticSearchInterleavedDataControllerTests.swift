import Foundation
import Testing
import WMFDataTestSupport
@testable import WMFData
@testable import WMFDataMocks

@Suite(.serialized)
final class WMFSemanticSearchInterleavedDataControllerTests {

    private let fixture = WMFDataTestFixture()
    private let controller = WMFSemanticSearchInterleavedDataController.shared

    @Test
    func isOffAndUnassignedWhileTheLocalFlagIsOff() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            #expect(controller.isEnabled == false)
            #expect(controller.isEligible(languageCode: "fr") == false)
            let enrolled = try controller.enrollIfNeeded(languageCode: "fr")
            #expect(enrolled == nil)
            #expect(controller.experimentAssignment == nil)
            #expect(controller.shouldInterleave(languageCode: "fr") == false)
        }
    }

    @Test
    func onlyTargetLanguagesEnroll() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            WMFDeveloperSettingsDataController.shared.enableSemanticSearchInterleaved = true

            let english = try controller.enrollIfNeeded(languageCode: "en")
            #expect(english == nil)
            #expect(controller.experimentAssignment == nil, "A reader who has not reached search on a target wiki has no arm")

            let french = try controller.enrollIfNeeded(languageCode: "fr")
            #expect(french != nil)
            #expect(controller.experimentAssignment != nil)
        }
    }

    @Test
    func assignmentStaysAcrossLaterSearchesAndLanguages() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            WMFDeveloperSettingsDataController.shared.enableSemanticSearchInterleaved = true

            let first = try #require(try controller.enrollIfNeeded(languageCode: "fr"))
            for languageCode in ["fr", "ar", "ja", "fr"] {
                let again = try controller.enrollIfNeeded(languageCode: languageCode)
                #expect(again == first)
            }
            #expect(controller.experimentAssignment == first)
        }
    }

    @Test
    func killSwitchReturnsEveryoneToLexicalWithoutLosingTheArm() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            WMFDeveloperSettingsDataController.shared.enableSemanticSearchInterleaved = true
            WMFDeveloperSettingsDataController.shared.forceSemanticSearchInterleavedExperimentAssignment = .treatment
            #expect(controller.shouldInterleave(languageCode: "fr"))
            #expect(controller.shouldInterleave(languageCode: "en") == false, "Not a target language")

            WMFDeveloperSettingsDataController.shared.enableSemanticSearchInterleaved = false
            #expect(controller.shouldInterleave(languageCode: "fr") == false)
            #expect(controller.experimentAssignment == .treatment)
        }
    }

    @Test
    func controlArmNeverInterleaves() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            WMFDeveloperSettingsDataController.shared.enableSemanticSearchInterleaved = true
            WMFDeveloperSettingsDataController.shared.forceSemanticSearchInterleavedExperimentAssignment = .control

            #expect(controller.shouldInterleave(languageCode: "fr") == false)
        }
    }

    @Test
    func rollSplitsAtTheControlShare() async throws {
        let store = WMFMockKeyValueStore()
        let experiments = WMFExperimentsDataController(store: store)
        let control = try experiments.determineBucketForExperiment(.semanticSearchInterleaved, withPercentage: 50, randomIntProvider: { 50 })
        try experiments.resetExperiment(.semanticSearchInterleaved)
        let treatment = try experiments.determineBucketForExperiment(.semanticSearchInterleaved, withPercentage: 50, randomIntProvider: { 51 })

        #expect(control == .semanticSearchInterleavedControl)
        #expect(treatment == .semanticSearchInterleavedGroupB)
    }

    @Test
    func forcedAssignmentIsReportedAsForcedAndDoesNotReplaceThePersistedArm() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            WMFDeveloperSettingsDataController.shared.enableSemanticSearchInterleaved = true
            let persisted = try #require(try controller.enrollIfNeeded(languageCode: "fr"))
            #expect(controller.experimentData?.coordinator == "custom")

            let forced: WMFSemanticSearchInterleavedDataController.ExperimentAssignment = persisted == .control ? .treatment : .control
            WMFDeveloperSettingsDataController.shared.forceSemanticSearchInterleavedExperimentAssignment = forced
            #expect(controller.experimentAssignment == forced)
            #expect(controller.experimentData?.coordinator == "forced")

            WMFDeveloperSettingsDataController.shared.forceSemanticSearchInterleavedExperimentAssignment = nil
            #expect(controller.experimentAssignment == persisted)
        }
    }

    @Test
    func experimentDataCarriesTheInstallIDAndArm() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            WMFDataEnvironment.current.appInstallIDUtility = { "install-id" }
            WMFDeveloperSettingsDataController.shared.enableSemanticSearchInterleaved = true
            WMFDeveloperSettingsDataController.shared.forceSemanticSearchInterleavedExperimentAssignment = .treatment

            let data = try #require(controller.experimentData)
            #expect(data.enrolled == WMFSemanticSearchInterleavedDataController.experimentName)
            #expect(data.assigned == "treatment")
            #expect(data.subjectId == "install-id")
        }
    }

    @Test
    func clearingTheAssignmentRerollsOnTheNextEligibleSearch() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            WMFDeveloperSettingsDataController.shared.enableSemanticSearchInterleaved = true
            try controller.enrollIfNeeded(languageCode: "fr")
            #expect(controller.experimentAssignment != nil)

            try controller.clearExperimentAssignment()
            #expect(controller.experimentAssignment == nil)

            try controller.enrollIfNeeded(languageCode: "fr")
            #expect(controller.experimentAssignment != nil)
        }
    }

    @Test
    func searchOpenEnrollsOnlyReadersWithATargetAppLanguage() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            WMFDeveloperSettingsDataController.shared.enableSemanticSearchInterleaved = true

            WMFDataEnvironment.current.appData = WMFAppData(appLanguages: [WMFLanguage(languageCode: "en", languageVariantCode: nil)])
            let englishOnly = try controller.enrollIfNeeded()
            #expect(englishOnly == nil)
            #expect(controller.experimentAssignment == nil)

            // The reader adds French before they ever reach search on a target wiki.
            WMFDataEnvironment.current.appData = WMFAppData(appLanguages: [
                WMFLanguage(languageCode: "en", languageVariantCode: nil),
                WMFLanguage(languageCode: "fr", languageVariantCode: nil)
            ])
            let withFrench = try controller.enrollIfNeeded()
            #expect(withFrench != nil)
            #expect(controller.experimentAssignment == withFrench)

            // Switching language again keeps the arm.
            WMFDataEnvironment.current.appData = WMFAppData(appLanguages: [WMFLanguage(languageCode: "en", languageVariantCode: nil)])
            let afterSwitch = try controller.enrollIfNeeded()
            #expect(afterSwitch == nil, "Not eligible now, but the persisted arm is untouched")
            #expect(controller.experimentAssignment == withFrench)
        }
    }

    @Test
    func addedTargetLanguageIsEligible() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            WMFDeveloperSettingsDataController.shared.enableSemanticSearchInterleaved = true
            #expect(controller.isEligible(languageCode: "en") == false)

            WMFDeveloperSettingsDataController.shared.addSemanticSearchInterleavedTargetLanguageCode = "en"
            #expect(controller.isEligible(languageCode: "en"))
            #expect(controller.isEligible(languageCode: "fr"), "The target languages stay")
            let assignment = try controller.enrollIfNeeded(languageCode: "en")
            #expect(assignment != nil)

            WMFDeveloperSettingsDataController.shared.addSemanticSearchInterleavedTargetLanguageCode = nil
            #expect(controller.isEligible(languageCode: "en") == false)
        }
    }

    @Test
    func addedTargetLanguageAlsoEnrollsOnSearchOpen() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            WMFDeveloperSettingsDataController.shared.enableSemanticSearchInterleaved = true
            WMFDataEnvironment.current.appData = WMFAppData(appLanguages: [WMFLanguage(languageCode: "en", languageVariantCode: nil)])
            let before = try controller.enrollIfNeeded()
            #expect(before == nil)

            WMFDeveloperSettingsDataController.shared.addSemanticSearchInterleavedTargetLanguageCode = "en"
            let after = try controller.enrollIfNeeded()
            #expect(after != nil)
        }
    }

    @Test
    func forcedRetrievalScenarioAppliesOnlyToInterleavedSearches() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            WMFDeveloperSettingsDataController.shared.enableSemanticSearchInterleaved = true
            WMFDeveloperSettingsDataController.shared.forceSemanticSearchInterleavedExperimentAssignment = .treatment
            #expect(controller.forcedRetrievalScenario(languageCode: "fr") == nil, "Nothing is forced yet")

            for scenario in WMFSemanticSearchInterleavedDataController.ForcedRetrievalScenario.allCases {
                WMFDeveloperSettingsDataController.shared.forceSemanticSearchInterleavedRetrievalScenario = scenario
                #expect(controller.forcedRetrievalScenario(languageCode: "fr") == scenario)
            }

            #expect(controller.forcedRetrievalScenario(languageCode: "en") == nil, "Not a target language")

            WMFDeveloperSettingsDataController.shared.forceSemanticSearchInterleavedExperimentAssignment = .control
            #expect(controller.forcedRetrievalScenario(languageCode: "fr") == nil, "Control readers see today's search")

            WMFDeveloperSettingsDataController.shared.forceSemanticSearchInterleavedExperimentAssignment = .treatment
            WMFDeveloperSettingsDataController.shared.enableSemanticSearchInterleaved = false
            #expect(controller.forcedRetrievalScenario(languageCode: "fr") == nil, "The kill switch wins")
        }
    }

    @Test
    func reinstallRollsAFreshArm() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            WMFDeveloperSettingsDataController.shared.enableSemanticSearchInterleaved = true
            try controller.enrollIfNeeded(languageCode: "fr")
            #expect(controller.experimentAssignment != nil)

            // A reinstall starts with empty stores.
            WMFDataEnvironment.current.sharedCacheStore = WMFMockKeyValueStore()
            WMFDataEnvironment.current.userDefaultsStore = WMFMockKeyValueStore()
            #expect(controller.experimentAssignment == nil)

            WMFDeveloperSettingsDataController.shared.enableSemanticSearchInterleaved = true
            try controller.enrollIfNeeded(languageCode: "fr")
            #expect(controller.experimentAssignment != nil)
        }
    }

    @Test
    func staysOffWhileDiveIsOn() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            WMFDeveloperSettingsDataController.shared.enableSemanticSearchInterleaved = true
            #expect(controller.isEnabled)
            #expect(controller.isEligible(languageCode: "fr"))

            WMFDeveloperSettingsDataController.shared.enableSemanticSearch = true
            #expect(controller.isEnabled == false)
            #expect(controller.isEligible(languageCode: "fr") == false)
            let enrolled = try controller.enrollIfNeeded(languageCode: "fr")
            #expect(enrolled == nil)
            #expect(controller.experimentAssignment == nil)
        }
    }

    @Test
    func diveKeepsRunningWhenBothFlagsAreOn() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let dive = WMFSemanticSearchDataController.shared
            WMFDeveloperSettingsDataController.shared.enableSemanticSearch = true
            WMFDeveloperSettingsDataController.shared.forceSemanticSearchExperimentAssignment = .groupB
            WMFDeveloperSettingsDataController.shared.enableSemanticSearchInterleaved = true

            #expect(dive.isEligible(languageCode: "fr"))
            #expect(dive.isEntryPointAvailable(languageCode: "fr"))
            #expect(dive.isSettingsEntryAvailable)
        }
    }

    @Test
    func exposureIsSentOncePerInstallInEitherArm() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            WMFDeveloperSettingsDataController.shared.enableSemanticSearchInterleaved = true
            #expect(controller.shouldSendExposure(languageCode: "fr") == false, "A reader with no arm has no exposure")

            WMFDeveloperSettingsDataController.shared.forceSemanticSearchInterleavedExperimentAssignment = .control
            #expect(controller.shouldSendExposure(languageCode: "fr"))
            #expect(controller.shouldSendExposure(languageCode: "en") == false, "Not a target language")

            try controller.markExposureSent()
            #expect(controller.shouldSendExposure(languageCode: "fr") == false)

            try controller.clearExperimentAssignment()
            #expect(controller.hasSentExposure == false, "A new assignment sends a new exposure")
        }
    }

    private func configureEnvironment() async {
        WMFDataEnvironment.current.userDefaultsStore = WMFMockKeyValueStore()
        WMFDataEnvironment.current.sharedCacheStore = WMFMockKeyValueStore()
    }
}

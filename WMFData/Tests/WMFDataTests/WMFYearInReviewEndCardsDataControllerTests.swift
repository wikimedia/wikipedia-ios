import Foundation
import Testing
@testable import WMFData
@testable import WMFDataMocks

struct WMFYearInReviewEndCardsDataControllerTests {

    private let experimentStore = WMFMockKeyValueStore()
    private let userDefaultsStore = WMFMockKeyValueStore()
    private let developerSettings: WMFDeveloperSettingsDataController

    init() {
        developerSettings = WMFDeveloperSettingsDataController(service: nil, sharedCacheStore: WMFMockKeyValueStore(), userDefaultsStore: userDefaultsStore)
    }

    private final class LanguageBox: @unchecked Sendable {
        // Unchecked: the tests read and write it on one thread only.
        var code: String?
        init(_ code: String?) { self.code = code }
    }

    private func makeController(languageCode: String? = "en") -> WMFYearInReviewEndCardsDataController {
        makeController(language: LanguageBox(languageCode))
    }

    private func makeController(language box: LanguageBox) -> WMFYearInReviewEndCardsDataController {
        let language: @Sendable () -> WMFLanguage? = { box.code.map { WMFLanguage(languageCode: $0, languageVariantCode: nil) } }
        return WMFYearInReviewEndCardsDataController(
            experimentStore: experimentStore,
            userDefaultsStore: userDefaultsStore,
            developerSettingsDataController: developerSettings,
            primaryAppLanguage: language
        )
    }

    // MARK: - Qualification

    @Test
    func aGameLanguageQualifies() {
        #expect(makeController(languageCode: "en").isQualified)
        #expect(makeController(languageCode: "TR").isQualified)
    }

    @Test
    func aLanguageWithoutTheGameDoesNotQualify() throws {
        let controller = makeController(languageCode: "it")

        #expect(controller.isQualified == false)
        #expect(try controller.assignIfNeeded() == nil)
        #expect(controller.assignment == nil)
        #expect(controller.experimentData == nil)
    }

    @Test
    func noPrimaryLanguageDoesNotQualify() throws {
        let controller = makeController(languageCode: nil)

        #expect(controller.isQualified == false)
        #expect(try controller.assignIfNeeded() == nil)
    }

    @Test
    func aLanguageWithoutTheGameIgnoresTheDeveloperOverride() {
        developerSettings.forceYiREndCardsExperimentAssignment = .groupB

        #expect(makeController(languageCode: "it").assignment == nil)
    }

    // MARK: - Assignment

    @Test
    func readingTheAssignmentDoesNotRollABucket() {
        let controller = makeController()

        #expect(controller.assignment == nil)
        #expect(controller.experimentData == nil)
    }

    @Test
    func assignmentPersists() throws {
        let controller = makeController()

        let first = try #require(try controller.assignIfNeeded())
        for _ in 0..<10 {
            #expect(try controller.assignIfNeeded() == first)
        }
        #expect(controller.assignment == first)
    }

    @Test
    func halfOfTheRollsGoToEachGroup() throws {
        let experiments = WMFExperimentsDataController(store: WMFMockKeyValueStore())

        let low = try experiments.determineBucketForExperiment(.yirEndCards, withPercentage: WMFYearInReviewEndCardsDataController.controlPercentage, randomIntProvider: { 50 })
        #expect(low == .yirEndCardsControl)

        try experiments.resetExperiment(.yirEndCards)
        let high = try experiments.determineBucketForExperiment(.yirEndCards, withPercentage: WMFYearInReviewEndCardsDataController.controlPercentage, randomIntProvider: { 51 })
        #expect(high == .yirEndCardsGroupB)
    }

    @Test
    func theDeveloperOverrideWinsAndKeepsThePersistedBucket() throws {
        let controller = makeController()
        let rolled = try #require(try controller.assignIfNeeded())
        let forced: WMFYearInReviewEndCardsDataController.Assignment = rolled == .control ? .groupB : .control

        developerSettings.forceYiREndCardsExperimentAssignment = forced
        #expect(controller.assignment == forced)
        #expect(try controller.assignIfNeeded() == forced)
        #expect(controller.experimentData?.coordinator == "forced")

        developerSettings.forceYiREndCardsExperimentAssignment = nil
        #expect(controller.assignment == rolled)
        #expect(controller.experimentData?.coordinator == "custom")
    }

    // MARK: - Experiment data

    @Test
    func experimentDataNamesTheGroup() throws {
        let controller = makeController()

        developerSettings.forceYiREndCardsExperimentAssignment = .groupB
        #expect(controller.experimentData?.enrolled == "year-in-review-end-screen")
        #expect(controller.experimentData?.assigned == "treatment")

        developerSettings.forceYiREndCardsExperimentAssignment = .control
        #expect(controller.experimentData?.assigned == "control")
    }

    // MARK: - Engagement cards

    @Test
    func groupBGetsBothCards() throws {
        developerSettings.forceYiREndCardsExperimentAssignment = .groupB

        let cards = try makeController().assignEngagementCardsIfNeeded()

        #expect(cards.showsGamesCard)
        #expect(cards.showsInterestsCard)
    }

    @Test
    func theControlGroupGetsNoCards() throws {
        developerSettings.forceYiREndCardsExperimentAssignment = .control

        let cards = try makeController().assignEngagementCardsIfNeeded()

        #expect(cards.showsGamesCard == false)
        #expect(cards.showsInterestsCard == false)
    }

    @Test
    func aLanguageWithoutTheGameGetsNoCardsAndNoBucket() throws {
        let cards = try makeController(languageCode: "it").assignEngagementCardsIfNeeded()

        #expect(cards.showsGamesCard == false)
        #expect(cards.showsInterestsCard == false)
        #expect(WMFExperimentsDataController(store: experimentStore).bucketForExperiment(.yirEndCards) == nil)
    }

    // MARK: - Exposure

    @Test
    func noExposureBeforeTheReaderHasAGroup() throws {
        var sent: [String] = []

        try makeController().recordEndScreenImpression { sent.append($0.enrolled) }

        #expect(sent.isEmpty)
    }

    @Test
    func exposureGoesOutOnceAfterAssignment() throws {
        let controller = makeController()
        try controller.assignIfNeeded()
        var sent: [String] = []

        try controller.recordEndScreenImpression { sent.append($0.enrolled) }
        try controller.recordEndScreenImpression { sent.append($0.enrolled) }

        #expect(sent.count == 1)
        #expect(sent.first == "year-in-review-end-screen")
        #expect(controller.hasSentExposure)
    }

    @Test
    func clearingTheAssignmentAllowsANewExposure() throws {
        let controller = makeController()
        try controller.assignIfNeeded()
        try controller.recordEndScreenImpression { _ in }

        try controller.clearAssignment()

        #expect(controller.assignment == nil)
        #expect(controller.hasSentExposure == false)
        try controller.assignIfNeeded()
        var sent = 0
        try controller.recordEndScreenImpression { _ in sent += 1 }
        #expect(sent == 1)
    }

    @Test
    func turningTheDeveloperOverrideOffClearsTheBucketAndTheExposure() throws {
        let controller = makeController()
        try controller.setDeveloperSettingsForcedAssignment(.groupB)
        try controller.assignIfNeeded()
        var coordinators: [String?] = []
        try controller.recordEndScreenImpression { coordinators.append($0.coordinator) }

        try controller.setDeveloperSettingsForcedAssignment(nil)

        #expect(developerSettings.forceYiREndCardsExperimentAssignment == nil)
        #expect(controller.assignment == nil)
        #expect(controller.hasSentExposure == false)
        try controller.assignIfNeeded()
        try controller.recordEndScreenImpression { coordinators.append($0.coordinator) }
        #expect(coordinators == ["forced", "custom"])
    }

    @Test
    func switchingBetweenForcedGroupsKeepsTheBucketAndTheExposure() throws {
        let controller = makeController()
        let rolled = try #require(try controller.assignIfNeeded())
        try controller.recordEndScreenImpression { _ in }

        try controller.setDeveloperSettingsForcedAssignment(.groupB)
        try controller.setDeveloperSettingsForcedAssignment(.control)

        #expect(controller.hasSentExposure)
        #expect(WMFExperimentsDataController(store: experimentStore).bucketForExperiment(.yirEndCards).flatMap { $0 == .yirEndCardsGroupB ? .groupB : .control } == rolled)
    }

    // MARK: - Language change after enrollment

    @Test
    func anEnrolledReaderStaysInTheTestAfterALanguageChange() throws {
        let language = LanguageBox("en")
        let controller = makeController(language: language)
        developerSettings.forceYiREndCardsExperimentAssignment = .groupB
        try controller.assignIfNeeded()
        try controller.recordEndScreenImpression { _ in }

        language.code = "it"

        #expect(controller.assignment == .groupB)
        #expect(controller.experimentData?.assigned == "treatment")
        let cards = try controller.assignEngagementCardsIfNeeded()
        #expect(cards.showsGamesCard == false)
        #expect(cards.showsInterestsCard)
    }

    @Test
    func aReaderWithABucketButNoExposureLeavesTheTestAfterALanguageChange() throws {
        let language = LanguageBox("en")
        let controller = makeController(language: language)
        try controller.assignIfNeeded()

        language.code = "it"

        #expect(controller.assignment == nil)
        #expect(controller.experimentData == nil)
    }
}

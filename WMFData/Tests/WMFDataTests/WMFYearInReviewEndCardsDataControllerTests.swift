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

    private func persistedBucket() -> WMFYearInReviewEndCardsDataController.Assignment? {
        switch WMFExperimentsDataController(store: experimentStore).bucketForExperiment(.yirEndCards) {
        case .yirEndCardsControl: return .control
        case .yirEndCardsGroupB: return .groupB
        default: return nil
        }
    }

    // MARK: - Qualification

    @Test
    func aGameLanguageQualifies() async {
        #expect(await makeController(languageCode: "en").isQualified)
        #expect(await makeController(languageCode: "TR").isQualified)
    }

    @Test
    func aLanguageWithoutTheGameDoesNotQualify() async throws {
        let controller = makeController(languageCode: "it")

        #expect(await controller.isQualified == false)
        #expect(try await controller.assignIfNeeded() == nil)
        #expect(await controller.assignment == nil)
        #expect(await controller.experimentData == nil)
    }

    @Test
    func noPrimaryLanguageDoesNotQualify() async throws {
        let controller = makeController(languageCode: nil)

        #expect(await controller.isQualified == false)
        #expect(try await controller.assignIfNeeded() == nil)
    }

    @Test
    func aLanguageWithoutTheGameIgnoresTheDeveloperOverride() async {
        developerSettings.forceYiREndCardsExperimentAssignment = .groupB

        #expect(await makeController(languageCode: "it").assignment == nil)
    }

    // MARK: - Assignment

    @Test
    func readingTheAssignmentDoesNotRollABucket() async {
        let controller = makeController()

        #expect(await controller.assignment == nil)
        #expect(await controller.experimentData == nil)
    }

    @Test
    func assignmentPersists() async throws {
        let controller = makeController()

        let first = try #require(try await controller.assignIfNeeded())
        for _ in 0..<10 {
            #expect(try await controller.assignIfNeeded() == first)
        }
        #expect(await controller.assignment == first)
    }

    /// Many calls at the same time roll one bucket, because the actor runs them one by one.
    @Test
    func callsAtTheSameTimeRollOneBucket() async throws {
        let controller = makeController()

        let results = try await withThrowingTaskGroup(of: WMFYearInReviewEndCardsDataController.EngagementCards.self) { group in
            for _ in 0..<20 {
                group.addTask { try await controller.assignEngagementCardsIfNeeded() }
            }
            return try await group.reduce(into: []) { $0.append($1) }
        }

        #expect(Set(results.map(\.showsInterestsCard)).count == 1)
        #expect(persistedBucket() == (results.first?.showsInterestsCard == true ? .groupB : .control))
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
    func theDeveloperOverrideWinsAndKeepsThePersistedBucket() async throws {
        let controller = makeController()
        let rolled = try #require(try await controller.assignIfNeeded())
        let forced: WMFYearInReviewEndCardsDataController.Assignment = rolled == .control ? .groupB : .control

        developerSettings.forceYiREndCardsExperimentAssignment = forced
        #expect(await controller.assignment == forced)
        #expect(try await controller.assignIfNeeded() == forced)
        #expect(await controller.experimentData?.coordinator == "forced")

        developerSettings.forceYiREndCardsExperimentAssignment = nil
        #expect(await controller.assignment == rolled)
        #expect(await controller.experimentData?.coordinator == "custom")
    }

    // MARK: - Experiment data

    @Test
    func experimentDataNamesTheGroup() async {
        let controller = makeController()

        developerSettings.forceYiREndCardsExperimentAssignment = .groupB
        #expect(await controller.experimentData?.enrolled == "year-in-review-end-screen")
        #expect(await controller.experimentData?.assigned == "treatment")

        developerSettings.forceYiREndCardsExperimentAssignment = .control
        #expect(await controller.experimentData?.assigned == "control")
    }

    // MARK: - Engagement cards

    @Test
    func groupBGetsBothCards() async throws {
        developerSettings.forceYiREndCardsExperimentAssignment = .groupB

        let cards = try await makeController().assignEngagementCardsIfNeeded()

        #expect(cards.showsGamesCard)
        #expect(cards.showsInterestsCard)
    }

    @Test
    func theControlGroupGetsNoCards() async throws {
        developerSettings.forceYiREndCardsExperimentAssignment = .control

        let cards = try await makeController().assignEngagementCardsIfNeeded()

        #expect(cards == .none)
    }

    @Test
    func aLanguageWithoutTheGameGetsNoCardsAndNoBucket() async throws {
        let cards = try await makeController(languageCode: "it").assignEngagementCardsIfNeeded()

        #expect(cards == .none)
        #expect(persistedBucket() == nil)
    }

    // MARK: - Exposure

    @Test
    func noExposureBeforeTheReaderHasAGroup() async throws {
        #expect(try await makeController().recordEndScreenImpression() == nil)
    }

    @Test
    func exposureGoesOutOnceAfterAssignment() async throws {
        let controller = makeController()
        try await controller.assignIfNeeded()

        let first = try await controller.recordEndScreenImpression()
        let second = try await controller.recordEndScreenImpression()

        #expect(first?.enrolled == "year-in-review-end-screen")
        #expect(second == nil)
        #expect(await controller.hasSentExposure)
    }

    @Test
    func clearingTheAssignmentAllowsANewExposure() async throws {
        let controller = makeController()
        try await controller.assignIfNeeded()
        _ = try await controller.recordEndScreenImpression()

        try await controller.clearAssignment()

        #expect(await controller.assignment == nil)
        #expect(await controller.hasSentExposure == false)
        try await controller.assignIfNeeded()
        #expect(try await controller.recordEndScreenImpression() != nil)
    }

    @Test
    func turningTheDeveloperOverrideOffClearsTheBucketAndTheExposure() async throws {
        let controller = makeController()
        try await controller.setDeveloperSettingsForcedAssignment(.groupB)
        try await controller.assignIfNeeded()
        let forcedExposure = try await controller.recordEndScreenImpression()

        try await controller.setDeveloperSettingsForcedAssignment(nil)

        #expect(developerSettings.forceYiREndCardsExperimentAssignment == nil)
        #expect(await controller.assignment == nil)
        #expect(await controller.hasSentExposure == false)
        try await controller.assignIfNeeded()
        let realExposure = try await controller.recordEndScreenImpression()
        #expect(forcedExposure?.coordinator == "forced")
        #expect(realExposure?.coordinator == "custom")
    }

    @Test
    func switchingBetweenForcedGroupsKeepsTheBucketAndTheExposure() async throws {
        let controller = makeController()
        let rolled = try #require(try await controller.assignIfNeeded())
        _ = try await controller.recordEndScreenImpression()

        try await controller.setDeveloperSettingsForcedAssignment(.groupB)
        try await controller.setDeveloperSettingsForcedAssignment(.control)

        #expect(await controller.hasSentExposure)
        #expect(persistedBucket() == rolled)
    }

    // MARK: - Language change after enrollment

    @Test
    func anEnrolledReaderStaysInTheTestAfterALanguageChange() async throws {
        let language = LanguageBox("en")
        let controller = makeController(language: language)
        developerSettings.forceYiREndCardsExperimentAssignment = .groupB
        try await controller.assignIfNeeded()
        _ = try await controller.recordEndScreenImpression()

        language.code = "it"

        #expect(await controller.assignment == .groupB)
        #expect(await controller.experimentData?.assigned == "treatment")
        let cards = try await controller.assignEngagementCardsIfNeeded()
        #expect(cards.showsGamesCard == false)
        #expect(cards.showsInterestsCard)
    }

    @Test
    func aReaderWithABucketButNoExposureLeavesTheTestAfterALanguageChange() async throws {
        let language = LanguageBox("en")
        let controller = makeController(language: language)
        try await controller.assignIfNeeded()

        language.code = "it"

        #expect(await controller.assignment == nil)
        #expect(await controller.experimentData == nil)
    }
}

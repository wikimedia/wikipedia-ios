import Foundation
import CoreData
import Testing
import WMFDataTestSupport
@testable import WMFData
@testable import WMFDataMocks

@Suite(.serialized)
final class WMFDiscoverReadingListDataControllerTests {

    private let fixture = WMFDataTestFixture()
    private let englishLanguage = WMFLanguage(languageCode: "en", languageVariantCode: nil)
    private var englishProject: WMFProject { .wikipedia(englishLanguage) }

    /// The titles the `related-pages-get` mock returns for every request.
    private let mockedRelatedTitles: Set<String> = ["Trap–neuter–return", "Purr", "Feral cat"]

    private var coreDataStore: WMFCoreDataStore?

    private func configureEnvironment() async throws {
        WMFDataEnvironment.current.userDefaultsStore = WMFMockKeyValueStore()
        WMFDataEnvironment.current.appData = WMFAppData(appLanguages: [englishLanguage])
        let store = try await fixture.makeTemporaryCoreDataStore()
        WMFDataEnvironment.current.coreDataStore = store
        coreDataStore = store
    }

    private func makeController(jsonResourceName: String = "related-pages-get") -> WMFDiscoverReadingListDataController {
        let relatedPagesDataController = WMFRelatedPagesDataController(basicService: WMFMockBasicService(jsonResourceName: jsonResourceName))
        return WMFDiscoverReadingListDataController(relatedPagesDataController: relatedPagesDataController)
    }

    private func addInterest(_ title: String) async throws {
        let interestsDataController = try WMFPageInterestDataController()
        try await interestsDataController.addPageInterest(title: title, project: englishProject)
    }

    private func saveSettings(_ settings: WMFDiscoverSettings, in controller: WMFDiscoverReadingListDataController) async throws {
        try await controller.saveSettings(settings)
    }

    private func insertSavedPage(title: String) async throws {
        let store = try #require(coreDataStore)
        let projectID = englishProject.id
        let context = try store.newBackgroundContext
        try await context.perform {
            let page = try store.create(entityType: CDPage.self, in: context)
            page.title = title
            page.namespaceID = 0
            page.projectID = projectID
            page.timestamp = Date()

            let savedInfo = try store.create(entityType: CDPageSavedInfo.self, in: context)
            savedInfo.savedDate = Date()
            savedInfo.page = page

            try store.saveIfNeeded(moc: context)
        }
    }

    // MARK: - Settings

    @Test
    func settingsDefaultToDisabledWeeklyInterestsWithFiveArticles() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let settings = await makeController().settings
            #expect(settings == .default)
            #expect(settings.isEnabled == false)
            #expect(settings.articleCount == 5)
            #expect(settings.cadence == .weekly)
            #expect(settings.source == .interests)
        }
    }

    @Test
    func settingsClampArticleCountToTheAllowedRange() {
        #expect(WMFDiscoverSettings(isEnabled: true, articleCount: 0, cadence: .daily, source: .saved).articleCount == 1)
        #expect(WMFDiscoverSettings(isEnabled: true, articleCount: 99, cadence: .daily, source: .saved).articleCount == 20)
    }

    @Test
    func settingsRoundTripThroughTheStore() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let controller = makeController()
            let settings = WMFDiscoverSettings(isEnabled: true, articleCount: 12, cadence: .monthly, source: .history)

            try await saveSettings(settings, in: controller)

            #expect(await controller.settings == settings)
        }
    }

    @Test
    func settingsDecodeWithMissingKeysUsingDefaults() throws {
        let json = Data(#"{"isEnabled": true}"#.utf8)
        let settings = try JSONDecoder().decode(WMFDiscoverSettings.self, from: json)
        #expect(settings.isEnabled == true)
        #expect(settings.articleCount == 5)
        #expect(settings.cadence == .weekly)
        #expect(settings.source == .interests)
    }

    // MARK: - Schedule

    private var utcCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) -> Date {
        utcCalendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    @Test
    func generationIsDueWhenNothingWasGeneratedYet() {
        #expect(WMFDiscoverSchedule.isGenerationDue(cadence: .weekly, lastGeneratedDate: nil, now: date(2026, 10, 26), calendar: utcCalendar))
    }

    @Test
    func generationIsNotDueWithinOneDayOfTheLastOne() {
        let monday = date(2026, 10, 26)
        let lastGenerated = monday.addingTimeInterval(-3600)
        #expect(WMFDiscoverSchedule.isGenerationDue(cadence: .daily, lastGeneratedDate: lastGenerated, now: monday, calendar: utcCalendar) == false)
    }

    @Test
    func dailyGenerationIsDueAfterOneDay() {
        let now = date(2026, 10, 27)
        #expect(WMFDiscoverSchedule.isGenerationDue(cadence: .daily, lastGeneratedDate: date(2026, 10, 26), now: now, calendar: utcCalendar))
    }

    @Test
    func weeklyGenerationIsDueOnlyOnMonday() {
        let lastGenerated = date(2026, 10, 19)
        #expect(WMFDiscoverSchedule.isGenerationDue(cadence: .weekly, lastGeneratedDate: lastGenerated, now: date(2026, 10, 26), calendar: utcCalendar))
        #expect(WMFDiscoverSchedule.isGenerationDue(cadence: .weekly, lastGeneratedDate: lastGenerated, now: date(2026, 10, 27), calendar: utcCalendar) == false)
    }

    @Test
    func monthlyGenerationIsDueOnlyOnTheFirstDayOfTheMonth() {
        let lastGenerated = date(2026, 10, 1)
        #expect(WMFDiscoverSchedule.isGenerationDue(cadence: .monthly, lastGeneratedDate: lastGenerated, now: date(2026, 11, 1), calendar: utcCalendar))
        #expect(WMFDiscoverSchedule.isGenerationDue(cadence: .monthly, lastGeneratedDate: lastGenerated, now: date(2026, 10, 31), calendar: utcCalendar) == false)
    }

    // MARK: - Generation

    @Test
    func generationFromInterestsFillsTheListWithRelatedPages() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await addInterest("Cat")
            let controller = makeController()
            try await saveSettings(WMFDiscoverSettings(isEnabled: true, articleCount: 2, cadence: .weekly, source: .interests), in: controller)
            let now = date(2026, 10, 26)

            let recommendations = try await controller.generateRecommendations(now: now)

            #expect(recommendations.count == 2)
            #expect(Set(recommendations.map(\.title)).isSubset(of: mockedRelatedTitles))
            #expect(recommendations.allSatisfy { $0.project == englishProject })
            #expect(recommendations.allSatisfy { $0.recommendedDate == now })
            #expect(await controller.lastGeneratedDate == now)
            #expect(try await controller.fetchCurrentRecommendations().map(\.title) == recommendations.map(\.title))
        }
    }

    @Test
    func generationKeepsDescriptionThumbnailAndExtract() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await addInterest("Cat")
            let controller = makeController()
            try await saveSettings(WMFDiscoverSettings(isEnabled: true, articleCount: 3, cadence: .weekly, source: .interests), in: controller)

            let recommendations = try await controller.generateRecommendations()

            let trapNeuterReturn = try #require(recommendations.first { $0.title == "Trap–neuter–return" })
            #expect(trapNeuterReturn.description == "Strategy for controlling feral animal populations")
            #expect(trapNeuterReturn.thumbnailURL?.absoluteString.hasSuffix("Trap-Neuter-Return_program.jpg") == true)
            #expect(trapNeuterReturn.extract?.hasPrefix("Trap–neuter–return (TNR)") == true)

            let purr = try #require(recommendations.first { $0.title == "Purr" })
            #expect(purr.thumbnailURL == nil)
        }
    }

    @Test
    func generationKeepsTheCanonicalTitleAndStoresTheDisplayTitle() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await addInterest("Smartphone")
            let controller = makeController(jsonResourceName: "related-pages-display-title-get")
            try await saveSettings(WMFDiscoverSettings(isEnabled: true, articleCount: 3, cadence: .weekly, source: .interests), in: controller)

            let generated = try await controller.generateRecommendations()
            let iPhone = try #require(generated.first { $0.title == "IPhone 3G" })
            #expect(iPhone.displayTitle == "iPhone 3G")

            let plain = try #require(generated.first { $0.title == "Plain title" })
            #expect(plain.displayTitle == "Plain title")

            let reloaded = try await controller.fetchCurrentRecommendations()
            let reloadedIPhone = try #require(reloaded.first { $0.title == "IPhone 3G" })
            #expect(reloadedIPhone.displayTitle == "iPhone 3G")
        }
    }

    @Test
    func regenerationExpiresThePreviousListAndNeverRepeatsFreshPages() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await addInterest("Cat")
            let controller = makeController()
            try await saveSettings(WMFDiscoverSettings(isEnabled: true, articleCount: 2, cadence: .daily, source: .interests), in: controller)

            let firstList = try await controller.generateRecommendations(now: date(2026, 10, 26))
            let secondList = try await controller.generateRecommendations(now: date(2026, 10, 27))

            // The mock only knows three pages: the second list takes the one unseen page and revives one expired page.
            #expect(secondList.count == 2)
            let unseenTitle = mockedRelatedTitles.subtracting(firstList.map(\.title))
            #expect(unseenTitle.isSubset(of: Set(secondList.map(\.title))))

            let currentTitles = try await controller.fetchCurrentRecommendations().map(\.title)
            #expect(Set(currentTitles) == Set(secondList.map(\.title)))

            let storedRows = try await controller.fetchStoredRecommendations(includeExpired: true)
            #expect(storedRows.count == 3)
            #expect(storedRows.filter(\.isExpired).count == 1)
        }
    }

    @Test
    func regenerationBackfillsFromExpiredPagesWhenNothingNewIsAvailable() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await addInterest("Cat")
            let controller = makeController()
            try await saveSettings(WMFDiscoverSettings(isEnabled: true, articleCount: 3, cadence: .daily, source: .interests), in: controller)

            _ = try await controller.generateRecommendations(now: date(2026, 10, 26))
            let secondList = try await controller.generateRecommendations(now: date(2026, 10, 27))

            #expect(Set(secondList.map(\.title)) == mockedRelatedTitles)
            let storedRows = try await controller.fetchStoredRecommendations(includeExpired: true)
            #expect(storedRows.count == 3)
            #expect(storedRows.allSatisfy { !$0.isExpired })
        }
    }

    @Test
    func generationWithAnEmptySourceThrowsAndKeepsThePreviousList() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await addInterest("Cat")
            let controller = makeController()
            try await saveSettings(WMFDiscoverSettings(isEnabled: true, articleCount: 2, cadence: .daily, source: .interests), in: controller)
            let firstList = try await controller.generateRecommendations(now: date(2026, 10, 26))

            try await saveSettings(WMFDiscoverSettings(isEnabled: true, articleCount: 2, cadence: .daily, source: .saved), in: controller)

            await #expect(throws: WMFDiscoverReadingListDataController.DiscoverReadingListError.sourceHasNoArticles(.saved)) {
                try await controller.generateRecommendations(now: self.date(2026, 10, 27))
            }
            #expect(try await controller.fetchCurrentRecommendations().map(\.title) == firstList.map(\.title))
        }
    }

    @Test
    func overlappingGenerationCallsShareOneRun() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await addInterest("Cat")
            let controller = makeController()
            try await saveSettings(WMFDiscoverSettings(isEnabled: true, articleCount: 2, cadence: .weekly, source: .interests), in: controller)
            let now = date(2026, 10, 26)

            async let firstList = controller.generateRecommendations(now: now)
            async let secondList = controller.generateRecommendationsIfNeeded(now: now)
            let (first, second) = try await (firstList, secondList)

            #expect(first.map(\.title) == second.map(\.title))
            #expect(try await controller.fetchCurrentRecommendations().count == 2)
            // One run persists one list. A second run would expire it and store more rows.
            #expect(try await controller.fetchStoredRecommendations(includeExpired: true).count == 2)
        }
    }

    @Test
    func generateIfNeededOnlyRegeneratesWhenDue() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await addInterest("Cat")
            let controller = makeController()
            try await saveSettings(WMFDiscoverSettings(isEnabled: true, articleCount: 2, cadence: .weekly, source: .interests), in: controller)
            let monday = date(2026, 10, 26)

            #expect(try await controller.isGenerationDue(now: monday))
            let firstList = try await controller.generateRecommendationsIfNeeded(now: monday)
            #expect(firstList.count == 2)

            let tuesday = date(2026, 10, 27)
            #expect(try await controller.isGenerationDue(now: tuesday) == false)
            let sameList = try await controller.generateRecommendationsIfNeeded(now: tuesday)
            #expect(sameList.map(\.title) == firstList.map(\.title))

            let nextMonday = date(2026, 11, 2)
            #expect(try await controller.isGenerationDue(now: nextMonday))
        }
    }

    @Test
    func changingTheSourceMakesGenerationDueImmediately() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await addInterest("Cat")
            try await insertSavedPage(title: "Dog")
            let controller = makeController()
            try await saveSettings(WMFDiscoverSettings(isEnabled: true, articleCount: 2, cadence: .weekly, source: .interests), in: controller)
            let monday = date(2026, 10, 26)
            _ = try await controller.generateRecommendations(now: monday)

            try await saveSettings(WMFDiscoverSettings(isEnabled: true, articleCount: 2, cadence: .weekly, source: .saved), in: controller)

            let tuesday = date(2026, 10, 27)
            #expect(try await controller.isGenerationDue(now: tuesday))
            _ = try await controller.generateRecommendationsIfNeeded(now: tuesday)
            #expect(try await controller.isGenerationDue(now: tuesday) == false)
            #expect(await controller.lastGeneratedDate == tuesday)
        }
    }

    @Test
    func changingOnlyTheCountDoesNotForceRegeneration() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await addInterest("Cat")
            let controller = makeController()
            try await saveSettings(WMFDiscoverSettings(isEnabled: true, articleCount: 2, cadence: .weekly, source: .interests), in: controller)
            _ = try await controller.generateRecommendations(now: date(2026, 10, 26))

            try await saveSettings(WMFDiscoverSettings(isEnabled: true, articleCount: 7, cadence: .weekly, source: .interests), in: controller)

            #expect(try await controller.isGenerationDue(now: date(2026, 10, 27)) == false)
        }
    }

    // MARK: - Seeds

    @Test
    func generationFromSavedArticlesUsesSavedPagesAsSeeds() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await insertSavedPage(title: "Dog")
            let controller = makeController()
            try await saveSettings(WMFDiscoverSettings(isEnabled: true, articleCount: 2, cadence: .weekly, source: .saved), in: controller)

            let recommendations = try await controller.generateRecommendations()

            #expect(recommendations.count == 2)
            #expect(Set(recommendations.map(\.title)).isSubset(of: mockedRelatedTitles))
        }
    }

    @Test
    func generationFromHistoryUsesRecentlyReadPagesAsSeeds() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let pageViewsDataController = try WMFPageViewsDataController()
            _ = try await pageViewsDataController.addPageView(title: "Dog", namespaceID: 0, project: englishProject, previousPageViewObjectID: nil)
            let controller = makeController()
            try await saveSettings(WMFDiscoverSettings(isEnabled: true, articleCount: 2, cadence: .weekly, source: .history), in: controller)

            let recommendations = try await controller.generateRecommendations()

            #expect(recommendations.count == 2)
            #expect(Set(recommendations.map(\.title)).isSubset(of: mockedRelatedTitles))
        }
    }

    @Test
    func deleteAllRecommendationsClearsTheListAndTheSchedule() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await addInterest("Cat")
            let controller = makeController()
            try await saveSettings(WMFDiscoverSettings(isEnabled: true, articleCount: 2, cadence: .weekly, source: .interests), in: controller)
            _ = try await controller.generateRecommendations(now: date(2026, 10, 26))

            try await controller.deleteAllRecommendations()

            #expect(try await controller.fetchCurrentRecommendations().isEmpty)
            #expect(try await controller.fetchStoredRecommendations(includeExpired: true).isEmpty)
            #expect(await controller.lastGeneratedDate == nil)
            #expect(try await controller.isGenerationDue(now: date(2026, 10, 27)))
        }
    }

    // MARK: - Migration

    /// Every model version that shipped before the current one. A reader can arrive from any of them.
    private static let previousModelVersionFileNames = ["WMFData", "WMFData 2", "WMFData 3", "WMFData 4", "WMFData 5", "WMFData 6", "WMFData 7", "WMFData 8"]

    /// Opens a database written with an older model version using the current model, which must succeed by lightweight migration.
    @Test(arguments: previousModelVersionFileNames)
    func storeWrittenWithAPreviousModelVersionMigratesToTheCurrentModel(modelFileName: String) async throws {
        try await fixture.withConfiguredEnvironment(configure: { WMFDataEnvironment.current.userDefaultsStore = WMFMockKeyValueStore() }) {
            let temporaryDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

            let modelDirectoryURL = try #require(WMFCoreDataStore.dataModelDirectoryURL)
            let previousModel = try #require(NSManagedObjectModel(contentsOf: modelDirectoryURL.appendingPathComponent("\(modelFileName).mom")))
            #expect(previousModel.entitiesByName["CDDiscoverRecommendation"] == nil)

            let databaseURL = temporaryDirectory.appendingPathComponent("WMFData.sqlite")
            let coordinator = NSPersistentStoreCoordinator(managedObjectModel: previousModel)
            let oldStore = try coordinator.addPersistentStore(type: .sqlite, at: databaseURL)
            let oldContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            oldContext.persistentStoreCoordinator = coordinator
            let projectID = englishProject.id
            try await oldContext.perform {
                let page = NSEntityDescription.insertNewObject(forEntityName: "CDPage", into: oldContext)
                page.setValue("Cat", forKey: "title")
                page.setValue(Int16(0), forKey: "namespaceID")
                page.setValue(projectID, forKey: "projectID")
                page.setValue(Date(), forKey: "timestamp")
                try oldContext.save()
            }
            try coordinator.remove(oldStore)

            let migratedStore = try await WMFCoreDataStore(appContainerURL: temporaryDirectory)
            let context = try migratedStore.newBackgroundContext
            let migratedTitles: [String] = try await context.perform {
                let pages = try migratedStore.fetch(entityType: CDPage.self, predicate: nil, fetchLimit: nil, in: context) ?? []
                return pages.compactMap(\.title)
            }
            #expect(migratedTitles == ["Cat"])

            let controller = WMFDiscoverReadingListDataController(coreDataStore: migratedStore, relatedPagesDataController: WMFRelatedPagesDataController(basicService: WMFMockBasicService(jsonResourceName: "related-pages-get")))
            try await controller.saveSettings(WMFDiscoverSettings(isEnabled: true, articleCount: 1, cadence: .weekly, source: .saved))
            #expect(try await controller.fetchCurrentRecommendations().isEmpty)
        }
    }
}

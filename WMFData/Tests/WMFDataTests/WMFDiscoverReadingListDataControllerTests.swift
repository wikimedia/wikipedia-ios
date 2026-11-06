import Foundation
import CoreData
import os
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

    private func makeController(jsonResourceName: String = "related-pages-get", topicArticlesResourceName: String = "random-articles-get") -> WMFDiscoverReadingListDataController {
        let relatedPagesDataController = WMFRelatedPagesDataController(basicService: WMFMockBasicService(jsonResourceName: jsonResourceName))
        let homeDataController = WMFHomeDataController(basicService: WMFMockBasicService(jsonResourceName: topicArticlesResourceName), userDefaultsStore: WMFMockKeyValueStore())
        return WMFDiscoverReadingListDataController(relatedPagesDataController: relatedPagesDataController, homeDataController: homeDataController)
    }

    /// Adds an article to the Discover interests, the set the generator reads.
    private func addInterest(_ title: String) async throws {
        try await WMFDiscoverInterestsDataController().addPage(title: title, project: englishProject)
    }

    /// Adds an article to the For You interests, which the generator must ignore.
    private func addForYouInterest(_ title: String) async throws {
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
    func savingChangedSettingsPostsTheListStateNotificationOnce() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let controller = makeController()
            let postCount = OSAllocatedUnfairLock(initialState: 0)
            let observer = NotificationCenter.default.addObserver(forName: WMFNSNotification.discoverListStateDidChange, object: nil, queue: nil) { _ in
                postCount.withLock { $0 += 1 }
            }
            defer { NotificationCenter.default.removeObserver(observer) }
            var settings = WMFDiscoverSettings.default
            settings.isEnabled = true

            try await saveSettings(settings, in: controller)
            #expect(postCount.withLock { $0 } == 1)

            try await saveSettings(settings, in: controller)
            #expect(postCount.withLock { $0 } == 1, "the same settings again post nothing")

            settings.isEnabled = false
            try await saveSettings(settings, in: controller)
            #expect(postCount.withLock { $0 } == 2)
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

    // MARK: - Available sources

    @Test
    func onlyInterestsIsAvailableWithoutSavedArticlesOrHistory() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let availableSources = try await makeController().availableSources()
            #expect(availableSources == [.interests])
        }
    }

    @Test
    func savedArticlesBecomeAvailableOnceOneArticleIsSaved() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await insertSavedPage(title: "Dog")

            let availableSources = try await makeController().availableSources()

            #expect(availableSources == [.interests, .saved])
        }
    }

    @Test
    func historyBecomesAvailableOnceOnePageWasRead() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let pageViewsDataController = try WMFPageViewsDataController()
            _ = try await pageViewsDataController.addPageView(title: "Dog", namespaceID: 0, project: englishProject, previousPageViewObjectID: nil)

            let availableSources = try await makeController().availableSources()

            #expect(availableSources == [.interests, .history])
        }
    }

    @Test
    func availableSourcesKeepTheInterestsSavedHistoryOrder() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let pageViewsDataController = try WMFPageViewsDataController()
            _ = try await pageViewsDataController.addPageView(title: "Dog", namespaceID: 0, project: englishProject, previousPageViewObjectID: nil)
            try await insertSavedPage(title: "Cat")

            let availableSources = try await makeController().availableSources()

            #expect(availableSources == [.interests, .saved, .history])
        }
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
    func dailyGenerationIsDueOnceTheNextDayStarts() {
        let mondayNight = date(2026, 10, 26, hour: 22)
        #expect(WMFDiscoverSchedule.isGenerationDue(cadence: .daily, lastGeneratedDate: mondayNight, now: date(2026, 10, 26, hour: 23), calendar: utcCalendar) == false)
        #expect(WMFDiscoverSchedule.isGenerationDue(cadence: .daily, lastGeneratedDate: mondayNight, now: date(2026, 10, 27, hour: 1), calendar: utcCalendar))
    }

    @Test
    func weeklyGenerationIsNotDueLaterInTheSameWeek() {
        let monday = date(2026, 10, 26)
        #expect(WMFDiscoverSchedule.isGenerationDue(cadence: .weekly, lastGeneratedDate: monday, now: date(2026, 10, 27), calendar: utcCalendar) == false)
        #expect(WMFDiscoverSchedule.isGenerationDue(cadence: .weekly, lastGeneratedDate: monday, now: date(2026, 11, 1, hour: 23), calendar: utcCalendar) == false)
    }

    @Test
    func weeklyGenerationIsDueOnTheFirstOpenOfANewWeek() {
        let monday = date(2026, 10, 26)
        #expect(WMFDiscoverSchedule.isGenerationDue(cadence: .weekly, lastGeneratedDate: monday, now: date(2026, 11, 2), calendar: utcCalendar))
        // The reader skips the next Monday and comes back on Tuesday.
        #expect(WMFDiscoverSchedule.isGenerationDue(cadence: .weekly, lastGeneratedDate: monday, now: date(2026, 11, 3), calendar: utcCalendar))
    }

    @Test
    func weeklyGenerationStartsTheWeekOnMondayInEveryLocale() {
        var sundayCalendar = utcCalendar
        sundayCalendar.firstWeekday = 1
        let saturday = date(2026, 10, 31)
        let sunday = date(2026, 11, 1)
        #expect(WMFDiscoverSchedule.isGenerationDue(cadence: .weekly, lastGeneratedDate: saturday, now: sunday, calendar: sundayCalendar) == false)
        #expect(WMFDiscoverSchedule.isGenerationDue(cadence: .weekly, lastGeneratedDate: sunday, now: date(2026, 11, 2), calendar: sundayCalendar))
    }

    @Test
    func monthlyGenerationIsNotDueLaterInTheSameMonth() {
        let firstOfOctober = date(2026, 10, 1)
        #expect(WMFDiscoverSchedule.isGenerationDue(cadence: .monthly, lastGeneratedDate: firstOfOctober, now: date(2026, 10, 31), calendar: utcCalendar) == false)
    }

    @Test
    func monthlyGenerationIsDueOnTheFirstOpenOfANewMonth() {
        let firstOfOctober = date(2026, 10, 1)
        #expect(WMFDiscoverSchedule.isGenerationDue(cadence: .monthly, lastGeneratedDate: firstOfOctober, now: date(2026, 11, 1), calendar: utcCalendar))
        // The reader skips the 1st and comes back on the 2nd.
        #expect(WMFDiscoverSchedule.isGenerationDue(cadence: .monthly, lastGeneratedDate: firstOfOctober, now: date(2026, 11, 2), calendar: utcCalendar))
    }

    // MARK: - Interest seeds

    @Test
    func forYouInterestsDoNotSeedTheDiscoverList() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await addForYouInterest("Cat")
            let controller = makeController()
            try await saveSettings(WMFDiscoverSettings(isEnabled: true, articleCount: 2, cadence: .weekly, source: .interests), in: controller)

            await #expect(throws: WMFDiscoverReadingListDataController.DiscoverReadingListError.sourceHasNoArticles(.interests)) {
                try await controller.generateRecommendations()
            }
        }
    }

    @Test
    func selectedTopicsSeedTheListWithArticlesFromThatTopic() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await WMFDiscoverInterestsDataController().setTopics([.music])
            let controller = makeController()

            let seeds = try await controller.fetchSeeds(source: .interests, count: 50)

            #expect(!seeds.isEmpty)
            #expect(seeds.contains { $0.title == "Armavir Province" })
            #expect(seeds.allSatisfy { $0.project == englishProject })
        }
    }

    @Test
    func interestSeedsCombineSelectedArticlesAndTopicArticles() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await addInterest("Cat")
            try await WMFDiscoverInterestsDataController().setTopics([.music])
            let controller = makeController()

            let seeds = try await controller.fetchSeeds(source: .interests, count: 50)

            #expect(seeds.contains { $0.title == "Cat" })
            #expect(seeds.contains { $0.title == "Armavir Province" })
        }
    }

    @Test
    func interestSeedsKeepTheSelectedArticlesWhenTheTopicFetchFails() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await addInterest("Cat")
            try await WMFDiscoverInterestsDataController().setTopics([.music])
            let controller = makeController(topicArticlesResourceName: "missing-resource")

            let seeds = try await controller.fetchSeeds(source: .interests, count: 50)

            #expect(seeds.map(\.title) == ["Cat"])
        }
    }

    @Test
    func topicsOnlyInterestsThrowWhenEveryTopicFetchFails() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await WMFDiscoverInterestsDataController().setTopics([.music])
            let controller = makeController(topicArticlesResourceName: "missing-resource")

            await #expect(throws: WMFDiscoverReadingListDataController.DiscoverReadingListError.recommendationsUnavailable, "the reader has interests, so this is not an empty source") {
                try await controller.fetchSeeds(source: .interests, count: 50)
            }
        }
    }

    @Test
    func interestSeedsWithoutACoreDataStoreThrow() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await addInterest("Cat")
            WMFDataEnvironment.current.coreDataStore = nil
            let controller = makeController()

            await #expect(throws: WMFDataControllerError.self, "the interests live in the store, so there is no set to seed from") {
                try await controller.fetchSeeds(source: .interests, count: 50)
            }
        }
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
    func theFirstGenerationStoresNothingWhenTheNetworkFails() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await addInterest("Cat")
            let controller = makeController(jsonResourceName: "missing-resource")
            try await saveSettings(WMFDiscoverSettings(isEnabled: true, articleCount: 2, cadence: .weekly, source: .interests), in: controller)

            await #expect(throws: WMFDiscoverReadingListDataController.DiscoverReadingListError.recommendationsUnavailable) {
                try await controller.generateRecommendations(now: date(2026, 10, 26))
            }

            #expect(try await controller.fetchStoredRecommendations(includeExpired: true).isEmpty, "an empty list is never stored")
            #expect(await controller.lastGeneratedDate == nil)
            #expect(await controller.hasUnseenList == false)
            #expect(try await controller.isGenerationDue(now: date(2026, 10, 26)), "the next check tries again")
        }
    }

    @Test
    func aGenerationThatGetsNoArticleKeepsThePreviousList() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await addInterest("Cat")
            let settings = WMFDiscoverSettings(isEnabled: true, articleCount: 2, cadence: .weekly, source: .interests)
            let onlineController = makeController()
            try await saveSettings(settings, in: onlineController)
            let previousList = try await onlineController.generateRecommendations(now: date(2026, 10, 26))
            try await onlineController.markCurrentListSeen()

            let offlineController = makeController(jsonResourceName: "missing-resource")
            await #expect(throws: WMFDiscoverReadingListDataController.DiscoverReadingListError.recommendationsUnavailable) {
                try await offlineController.generateRecommendations(now: date(2026, 11, 2))
            }

            #expect(try await offlineController.fetchCurrentRecommendations().map(\.title) == previousList.map(\.title), "the previous list is not expired")
            #expect(await offlineController.lastGeneratedDate == date(2026, 10, 26))
            #expect(await offlineController.hasUnseenList == false)
        }
    }

    @Test
    func aFailedRunKeepsTheRegenerationDue() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await addInterest("Cat")
            let onlineController = makeController()
            try await saveSettings(WMFDiscoverSettings(isEnabled: true, articleCount: 2, cadence: .weekly, source: .interests), in: onlineController)
            _ = try await onlineController.generateRecommendations(now: date(2026, 10, 26))
            try await saveSettings(WMFDiscoverSettings(isEnabled: true, articleCount: 3, cadence: .weekly, source: .interests), in: onlineController)

            let offlineController = makeController(jsonResourceName: "missing-resource")
            await #expect(throws: WMFDiscoverReadingListDataController.DiscoverReadingListError.recommendationsUnavailable) {
                try await offlineController.generateRecommendations(now: date(2026, 10, 26))
            }

            #expect(try await offlineController.needsRegeneration(), "the new article count still waits for a list")
            #expect(try await offlineController.isGenerationDue(now: date(2026, 10, 26)))
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
    func changingTheArticleCountMakesGenerationDueImmediately() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await addInterest("Cat")
            let controller = makeController()
            try await saveSettings(WMFDiscoverSettings(isEnabled: true, articleCount: 2, cadence: .weekly, source: .interests), in: controller)
            let monday = date(2026, 10, 26)
            _ = try await controller.generateRecommendations(now: monday)

            try await saveSettings(WMFDiscoverSettings(isEnabled: true, articleCount: 3, cadence: .weekly, source: .interests), in: controller)

            let tuesday = date(2026, 10, 27)
            #expect(try await controller.isGenerationDue(now: tuesday))
            let regeneratedList = try await controller.generateRecommendationsIfNeeded(now: tuesday)
            #expect(regeneratedList.count == 3)
            #expect(try await controller.isGenerationDue(now: tuesday) == false)
            #expect(await controller.lastGeneratedDate == tuesday)
        }
    }

    @Test
    func changingTheInterestsMakesGenerationDueImmediately() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await addInterest("Cat")
            let controller = makeController()
            try await saveSettings(WMFDiscoverSettings(isEnabled: true, articleCount: 2, cadence: .weekly, source: .interests), in: controller)
            _ = try await controller.generateRecommendations(now: date(2026, 10, 26))
            #expect(try await controller.isGenerationDue(now: date(2026, 10, 27)) == false)

            try await addInterest("Dog")

            #expect(try await controller.isGenerationDue(now: date(2026, 10, 27)))
        }
    }

    @Test
    func aSourceChangeUndoneBeforeTheCheckKeepsTheCurrentList() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await addInterest("Cat")
            try await insertSavedPage(title: "Dog")
            let controller = makeController()
            let originalSettings = WMFDiscoverSettings(isEnabled: true, articleCount: 2, cadence: .weekly, source: .interests)
            try await saveSettings(originalSettings, in: controller)
            let monday = date(2026, 10, 26)
            let originalList = try await controller.generateRecommendations(now: monday)

            try await saveSettings(WMFDiscoverSettings(isEnabled: true, articleCount: 2, cadence: .weekly, source: .saved), in: controller)
            try await saveSettings(originalSettings, in: controller)

            let tuesday = date(2026, 10, 27)
            #expect(try await controller.isGenerationDue(now: tuesday) == false, "the list still matches the settings")
            let sameList = try await controller.generateRecommendationsIfNeeded(now: tuesday)
            #expect(sameList.map(\.title) == originalList.map(\.title))
            #expect(await controller.lastGeneratedDate == monday)
        }
    }

    @Test
    func changingOnlyTheCadenceKeepsTheCurrentList() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await addInterest("Cat")
            let controller = makeController()
            try await saveSettings(WMFDiscoverSettings(isEnabled: true, articleCount: 2, cadence: .weekly, source: .interests), in: controller)
            _ = try await controller.generateRecommendations(now: date(2026, 10, 26))

            try await saveSettings(WMFDiscoverSettings(isEnabled: true, articleCount: 2, cadence: .monthly, source: .interests), in: controller)

            #expect(try await controller.isGenerationDue(now: date(2026, 10, 27)) == false)
        }
    }

    @Test
    func turnOffThrowsTheListAwayAndKeepsTheOtherSettings() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await addInterest("Cat")
            let controller = makeController()
            try await saveSettings(WMFDiscoverSettings(isEnabled: true, articleCount: 2, cadence: .monthly, source: .interests), in: controller)
            _ = try await controller.generateRecommendations(now: date(2026, 10, 26))

            try await controller.turnOff()

            #expect(await controller.settings == WMFDiscoverSettings(isEnabled: false, articleCount: 2, cadence: .monthly, source: .interests))
            #expect(try await controller.fetchStoredRecommendations(includeExpired: true).isEmpty)
            #expect(await controller.lastGeneratedDate == nil)
        }
    }

    @Test
    func turnOffShowsTheOnboardingToastAgain() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let controller = makeController()
            try await controller.markOnboardingToastShown()

            try await controller.turnOff()

            #expect(await controller.hasShownOnboardingToast == false)
        }
    }

    @Test
    func aSettingsChangeDuringAGenerationStillMakesTheNextGenerationDue() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await addInterest("Cat")
            let controller = makeController()
            try await saveSettings(WMFDiscoverSettings(isEnabled: true, articleCount: 2, cadence: .weekly, source: .interests), in: controller)
            let monday = date(2026, 10, 26)
            _ = try await controller.generateRecommendations(now: monday)

            async let secondList = controller.generateRecommendations(now: monday)
            // The run has started once the first list is expired.
            while try await controller.fetchStoredRecommendations(includeExpired: true).contains(where: \.isExpired) == false {
                await Task.yield()
            }
            try await saveSettings(WMFDiscoverSettings(isEnabled: true, articleCount: 2, cadence: .weekly, source: .history), in: controller)
            _ = try await secondList

            #expect(try await controller.isGenerationDue(now: date(2026, 10, 27)))
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

    // MARK: - Unseen list

    @Test
    func generationMarksTheListAsUnseen() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await addInterest("Cat")
            let controller = makeController()
            try await saveSettings(WMFDiscoverSettings(isEnabled: true, articleCount: 2, cadence: .weekly, source: .interests), in: controller)
            #expect(await controller.hasUnseenList == false)

            _ = try await controller.generateRecommendations(now: date(2026, 10, 26))

            #expect(await controller.hasUnseenList)
        }
    }

    @Test
    func openingTheListClearsTheUnseenFlag() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await addInterest("Cat")
            let controller = makeController()
            try await saveSettings(WMFDiscoverSettings(isEnabled: true, articleCount: 2, cadence: .weekly, source: .interests), in: controller)
            _ = try await controller.generateRecommendations(now: date(2026, 10, 26))

            try await controller.markCurrentListSeen()

            #expect(await controller.hasUnseenList == false)
            #expect(try await controller.fetchCurrentRecommendations().count == 2)
        }
    }

    @Test
    func regenerationMarksTheListAsUnseenAgain() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await addInterest("Cat")
            let controller = makeController()
            try await saveSettings(WMFDiscoverSettings(isEnabled: true, articleCount: 2, cadence: .weekly, source: .interests), in: controller)
            _ = try await controller.generateRecommendations(now: date(2026, 10, 26))
            try await controller.markCurrentListSeen()

            _ = try await controller.generateRecommendations(now: date(2026, 11, 2))

            #expect(await controller.hasUnseenList)
        }
    }

    @Test
    func deleteAllRecommendationsClearsTheUnseenFlag() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await addInterest("Cat")
            let controller = makeController()
            try await saveSettings(WMFDiscoverSettings(isEnabled: true, articleCount: 2, cadence: .weekly, source: .interests), in: controller)
            _ = try await controller.generateRecommendations(now: date(2026, 10, 26))

            try await controller.deleteAllRecommendations()

            #expect(await controller.hasUnseenList == false)
        }
    }

    @Test
    func unseenListBadgeNeedsTheFeatureAndTheListTurnedOn() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await addInterest("Cat")
            let controller = makeController()
            let badgeController = WMFDiscoverDataController.shared
            try await saveSettings(WMFDiscoverSettings(isEnabled: true, articleCount: 2, cadence: .weekly, source: .interests), in: controller)
            _ = try await controller.generateRecommendations(now: date(2026, 10, 26))

            #expect(badgeController.shouldShowUnseenListBadge == false)

            WMFDeveloperSettingsDataController.shared.enableDiscover = true
            #expect(badgeController.shouldShowUnseenListBadge)

            try await saveSettings(WMFDiscoverSettings(isEnabled: false, articleCount: 2, cadence: .weekly, source: .interests), in: controller)
            #expect(badgeController.shouldShowUnseenListBadge == false)

            try await saveSettings(WMFDiscoverSettings(isEnabled: true, articleCount: 2, cadence: .weekly, source: .interests), in: controller)
            try await controller.markCurrentListSeen()
            #expect(badgeController.shouldShowUnseenListBadge == false)
        }
    }
}

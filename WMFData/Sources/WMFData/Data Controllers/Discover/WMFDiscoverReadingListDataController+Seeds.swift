import Foundation

extension WMFDiscoverReadingListDataController {

    /// The sources the setup screen offers. Interests is always offered. Saved articles and
    /// reading history are offered only when they hold at least one article to seed from.
    public func availableSources() async throws -> [WMFDiscoverSource] {
        var availableSources: [WMFDiscoverSource] = []
        for source in WMFDiscoverSource.allCases {
            if source == .interests {
                availableSources.append(source)
                continue
            }

            let seeds = try await fetchSeeds(source: source, count: 1)
            if !seeds.isEmpty {
                availableSources.append(source)
            }
        }
        return availableSources
    }

    /// Samples up to `count` seed articles from the selected source, like the Android app does.
    func fetchSeeds(source: WMFDiscoverSource, count: Int) async throws -> [Seed] {
        guard let coreDataStore else {
            throw WMFDataControllerError.coreDataStoreUnavailable
        }

        let candidates: [Seed]
        switch source {
        case .interests:
            candidates = try await fetchInterestSeeds(coreDataStore: coreDataStore)
        case .saved:
            candidates = try await fetchSavedSeeds(coreDataStore: coreDataStore)
        case .history:
            candidates = try await fetchHistorySeeds(coreDataStore: coreDataStore)
        }

        return Array(Set(candidates).shuffled().prefix(count))
    }

    private func fetchInterestSeeds(coreDataStore: WMFCoreDataStore) async throws -> [Seed] {
        let interestsDataController = try WMFPageInterestDataController(coreDataStore: coreDataStore)
        let interests = try await interestsDataController.fetchAllPageInterests()

        return interests.compactMap { interest in
            guard let project = interest.project else {
                return nil
            }

            return Seed(title: interest.title.underscoresToSpaces, project: project)
        }
    }

    private func fetchSavedSeeds(coreDataStore: WMFCoreDataStore) async throws -> [Seed] {
        let savedArticlesDataController = WMFSavedArticlesDataController(coreDataStore: coreDataStore)
        let savedPages = try await savedArticlesDataController.fetchTimelinePages()

        return savedPages.compactMap { savedPage in
            Seed(page: savedPage.page)
        }
    }

    /// Reading history is stored per project, so every app language is asked for its own pages.
    private func fetchHistorySeeds(coreDataStore: WMFCoreDataStore) async throws -> [Seed] {
        let pageViewsDataController = try WMFPageViewsDataController(coreDataStore: coreDataStore, userDefaultsStore: userDefaultsStore)

        var seeds: [Seed] = []
        for language in WMFDataEnvironment.current.appData.appLanguages {
            let project = WMFProject.wikipedia(language)
            let pages = try await pageViewsDataController.fetchRecentlyReadPages(project: project, minimumSeconds: 0, withinDays: 365, mainNamespaceOnly: true)
            seeds.append(contentsOf: pages.compactMap(Seed.init(page:)))
        }

        return seeds
    }
}

private extension WMFDiscoverReadingListDataController.Seed {

    /// Nil for pages outside the main namespace or from a project the app no longer knows.
    init?(page: WMFPage) {
        guard page.namespaceID == 0, let project = WMFProject(id: page.projectID) else {
            return nil
        }

        self.init(title: page.title.underscoresToSpaces, project: project)
    }
}

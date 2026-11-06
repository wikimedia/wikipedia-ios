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
        let candidates: [Seed]
        switch source {
        case .interests:
            candidates = try await fetchInterestSeeds()
        case .saved:
            candidates = try await fetchSavedSeeds(coreDataStore: requireCoreDataStore())
        case .history:
            candidates = try await fetchHistorySeeds(coreDataStore: requireCoreDataStore())
        }

        return Array(Set(candidates).shuffled().prefix(count))
    }

    private func requireCoreDataStore() throws -> WMFCoreDataStore {
        guard let coreDataStore else {
            throw WMFDataControllerError.coreDataStoreUnavailable
        }
        return coreDataStore
    }

    /// The Discover interests: every selected article, plus articles from every selected topic on
    /// the primary app language. A topic whose articles cannot be fetched adds no seeds, so the
    /// selected articles still seed the list. With topics only, a set that gives no seed at all
    /// throws `recommendationsUnavailable`, because the interests are there and the network is not.
    /// A stopped run leaves the loop at the next topic.
    private func fetchInterestSeeds() async throws -> [Seed] {
        let interests = try await interestsDataController.fetchInterests()
        var seeds = interests.pages.map { page in
            Seed(title: page.title.underscoresToSpaces, project: page.project)
        }

        guard !interests.topics.isEmpty, let primaryAppLanguage = WMFDataEnvironment.current.primaryAppLanguage else {
            return seeds
        }

        let project = WMFProject.wikipedia(primaryAppLanguage)
        for topic in interests.topics {
            try Task.checkCancellation()
            let articles = (try? await homeDataController.fetchArticles(for: topic, project: project)) ?? []
            seeds.append(contentsOf: articles.map { Seed(title: $0.title.underscoresToSpaces, project: project) })
        }

        guard !seeds.isEmpty else {
            throw DiscoverReadingListError.recommendationsUnavailable
        }
        return seeds
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

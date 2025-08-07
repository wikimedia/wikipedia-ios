import Foundation
import UIKit
import CoreData

public protocol WMFArticleTabsDataControlling {
    func tabsCount() async throws -> Int
    func checkAndCreateInitialArticleTabIfNeeded() async throws
    func createArticleTab(initialArticle: WMFArticleTabsDataController.WMFArticle?, setAsCurrent: Bool) async throws -> WMFArticleTabsDataController.Identifiers
    func deleteArticleTab(identifier: UUID) async throws
    func appendArticle(_ article: WMFArticleTabsDataController.WMFArticle, toTabIdentifier identifier: UUID, needsCleanoutOfFutureArticles: Bool) async throws -> WMFArticleTabsDataController.Identifiers
    func setTabItemAsCurrent(tabIdentifier: UUID, tabItemIdentifier: UUID) async throws
    func setTabAsCurrent(tabIdentifier: UUID) async throws
    func currentTabIdentifier() async throws -> UUID
    func fetchAllArticleTabs() async throws -> [WMFArticleTabsDataController.WMFArticleTab]
}

public class WMFArticleTabsDataController: WMFArticleTabsDataControlling {

    // MARK: - Nested Public Types
    
    public enum CustomError: Error {
        case missingTab
        case missingTabItem
        case missingSelf
        case cannotDeleteLastTab
        case missingPage
        case unexpectedType
        case missingIdentifier
        case missingTimestamp
        case missingContext
        case missingAppLanguage
        case missingExperimentsDataController
        case unexpectedAssignment
        case missingAssignment
        case doesNotQualifyForExperiment
        case pastAssignmentEndDate
    }
    
    public struct WMFArticle: Codable {
        public let identifier: UUID?
        public let title: String
        public let description: String?
        public let extract: String?
        public let imageURL: URL?
        public let project: WMFProject
        
        public init(identifier: UUID?, title: String, description: String? = nil, extract: String? = nil, imageURL: URL? = nil, project: WMFProject) {
            self.identifier = identifier
            self.title = title
            self.description = description
            self.extract = extract
            self.imageURL = imageURL
            self.project = project
        }
        
        public var isMain: Bool {
            return title == "Main_Page" || title == "Main Page"
        }
    }
    
    public struct WMFArticleTab: Codable, Equatable {
        public static func == (lhs: WMFArticleTabsDataController.WMFArticleTab, rhs: WMFArticleTabsDataController.WMFArticleTab) -> Bool {
            return lhs.identifier == rhs.identifier
        }
        
        public let identifier: UUID
        public let timestamp: Date
        public let isCurrent: Bool
        public let articles: [WMFArticle]
        
        public init(identifier: UUID, timestamp: Date, isCurrent: Bool, articles: [WMFArticle]) {
            self.identifier = identifier
            self.timestamp = timestamp
            self.isCurrent = isCurrent
            self.articles = articles
        }
    }
    
    public struct Identifiers {
        public let tabIdentifier: UUID
        public let tabItemIdentifier: UUID?
        
        public init(tabIdentifier: UUID, tabItemIdentifier: UUID?) {
            self.tabIdentifier = tabIdentifier
            self.tabItemIdentifier = tabItemIdentifier
        }
    }

    public enum MoreDynamicTabsExperimentAssignment {
        case control
        case becauseYouRead
        case didYouKnow
    }

    // MARK: Nested internal types

    struct OnboardingStatus: Codable {
        var hasPresentedOnboardingTooltips: Bool
        var hasPresentedOnboardingTabs: Bool

        static var `default`: OnboardingStatus {
            return OnboardingStatus(hasPresentedOnboardingTooltips: false, hasPresentedOnboardingTabs: false)
        }
    }

    // MARK: - Properties
    
    public static let shared = WMFArticleTabsDataController()
    
    private let userDefaultsStore = WMFDataEnvironment.current.userDefaultsStore
    private let developerSettingsDataController: WMFDeveloperSettingsDataControlling
    
    private let experimentsDataController: WMFExperimentsDataController?
    private var assignmentCache: MoreDynamicTabsExperimentAssignment?

    private let moreDynamicTabsExperimentPercentage: Int = 33

    // This setup allows us to try instantiation multiple times in case the first attempt fails (like for example, if coreDataStore is not available yet).
    private var _backgroundContext: NSManagedObjectContext?
    public var backgroundContext: NSManagedObjectContext? {
        get {
            if _backgroundContext == nil {
                _backgroundContext = try? coreDataStore?.newBackgroundContext
                _backgroundContext?.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            }
            return _backgroundContext
        } set {
            _backgroundContext = newValue
        }
    }
    
    private var _coreDataStore: WMFCoreDataStore?
    private var coreDataStore: WMFCoreDataStore? {
        return _coreDataStore ?? WMFDataEnvironment.current.coreDataStore
    }
    
    // MARK: - Lifecycle
    
    init(coreDataStore: WMFCoreDataStore? = WMFDataEnvironment.current.coreDataStore,
         developerSettingsDataController: WMFDeveloperSettingsDataControlling = WMFDeveloperSettingsDataController.shared,
         experimentStore: WMFKeyValueStore? = WMFDataEnvironment.current.sharedCacheStore) {
        self._coreDataStore = coreDataStore
        self.developerSettingsDataController = developerSettingsDataController
        if let experimentStore {
            self.experimentsDataController = WMFExperimentsDataController(store: experimentStore)
        } else {
            self.experimentsDataController = nil
        }
    }

    // MARK: - Experiment


    public func shouldAssignToBucket() -> Bool {
        return experimentsDataController?.bucketForExperiment(.moreDynamicTabs) == nil
    }

    public var shouldShowMoreDynamicTabs: Bool {
        guard !developerSettingsDataController.enableMoreDynamicTabsDYK else {
            return true
        }

        guard !developerSettingsDataController.enableMoreDynamicTabsBYR else {
            return true
        }

        guard let assignment = try? getMoreDynamicTabsExperimentAssignment() else {
            return false
        }

        switch assignment {
        case .becauseYouRead, .didYouKnow:
            return true
        case .control:
            return false
        }
    }

    private var primaryAppLanguageProject: WMFProject? {
        if let language = WMFDataEnvironment.current.appData.appLanguages.first {
            return WMFProject.wikipedia(language)
        }
        
        return nil
    }

    private var isBeforeAssignmentEndDate: Bool {
        var dateComponents = DateComponents()
        dateComponents.year = 2025
        dateComponents.month = 9
        dateComponents.day = 30
        guard let endDate = Calendar.current.date(from: dateComponents) else {
            return false
        }
        
        return endDate >= Date()
    }

    public func qualifiesForExperiment() -> Bool {
        guard let primaryAppLanguageProject else {
            return false
        }

        return Locale.current.qualifiesForExperiment && primaryAppLanguageProject.qualifiesForExperiment
    }

    public func getMoreDynamicTabsExperimentAssignment() throws -> MoreDynamicTabsExperimentAssignment {
        guard qualifiesForExperiment() else {
            throw CustomError.doesNotQualifyForExperiment
        }

        guard let experimentsDataController else {
            throw CustomError.missingExperimentsDataController
        }

        if let assignmentCache {
            return assignmentCache
        }

        guard let bucketValue = experimentsDataController.bucketForExperiment(.moreDynamicTabs) else {
            throw CustomError.missingAssignment
        }

        let assignment: MoreDynamicTabsExperimentAssignment
        switch bucketValue {

        case .moreDynamicTabsControl:
            assignment = .control
        case .moreDynamicTabsBecauseYouRead:
            assignment = .becauseYouRead
        case .moreDynamicTabsDidYouKnow:
            assignment = .didYouKnow
        default:
            throw CustomError.unexpectedAssignment
        }

        self.assignmentCache = assignment
        return assignment
    }

    public func assignExperiment() throws -> MoreDynamicTabsExperimentAssignment {
        guard qualifiesForExperiment() else {
            throw CustomError.doesNotQualifyForExperiment
        }

        guard isBeforeAssignmentEndDate else {
            throw CustomError.pastAssignmentEndDate
        }

        guard let experimentsDataController else {
            throw CustomError.missingExperimentsDataController
        }

        let bucketValue = try experimentsDataController.determineBucketForExperiment(.moreDynamicTabs, withPercentage: moreDynamicTabsExperimentPercentage)

        let assignment: MoreDynamicTabsExperimentAssignment

        switch bucketValue {
        case .moreDynamicTabsControl:
            assignment = .control
        case .moreDynamicTabsBecauseYouRead:
            assignment = .becauseYouRead
        case .moreDynamicTabsDidYouKnow:
            assignment = .didYouKnow
        default:
            throw CustomError.unexpectedAssignment
        }

        self.assignmentCache = assignment
        return assignment
    }

    // MARK: Onboarding

    internal var onboardingStatus: OnboardingStatus {
        get {
            return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.articleTabsOnboarding.rawValue)) ?? OnboardingStatus.default
        }
    }

    public var hasPresentedTooltips: Bool {
        get {
            return onboardingStatus.hasPresentedOnboardingTooltips
        } set {
            var currentStatus = onboardingStatus
            currentStatus.hasPresentedOnboardingTooltips = newValue
            try? userDefaultsStore?.save(key: WMFUserDefaultsKey.articleTabsOnboarding.rawValue, value: currentStatus)
        }
    }
    
    public var hasSeenFeatureAnnouncement: Bool {
        get {
            return onboardingStatus.hasPresentedOnboardingTabs
        }
        set {
            var currentStatus = onboardingStatus
            currentStatus.hasPresentedOnboardingTabs = newValue
            try? userDefaultsStore?.save(key: WMFUserDefaultsKey.articleTabsOnboarding.rawValue, value: currentStatus)
        }
    }
    
    // MARK: - Tabs Manipulation Methods
    
    public func tabsCount() async throws -> Int {
        
        guard let moc = backgroundContext else {
            throw CustomError.missingContext
        }
        
        return try await moc.perform {
            let fetchRequest = NSFetchRequest<CDArticleTab>(entityName: "CDArticleTab")
            return try moc.count(for: fetchRequest)
        }
    }
    
    public func checkAndCreateInitialArticleTabIfNeeded() async throws {
        let count = try await tabsCount()
        if count == 0 {
            _ = try await createArticleTab(initialArticle: nil, setAsCurrent: true)
        }
    }
    
    public var tabsMax: Int {
        return developerSettingsDataController.forceMaxArticleTabsTo5 ? 5 : 500
    }

    public func createArticleTab(initialArticle: WMFArticle?, setAsCurrent: Bool = false) async throws -> Identifiers {
        
        guard let coreDataStore else {
            throw WMFDataControllerError.coreDataStoreUnavailable
        }
        
        guard let moc = backgroundContext else {
            throw CustomError.missingContext
        }
        
        let article: WMFArticle
        
        if let initialArticle {
            article = initialArticle
        } else {
            if let primaryAppLanguage = WMFDataEnvironment.current.appData.appLanguages.first {
                let project = WMFProject.wikipedia(primaryAppLanguage)
                article = WMFArticle(identifier: nil, title: "Main_Page", project: project)
            } else {
                throw CustomError.missingAppLanguage
            }
        }
        
        return try await moc.perform { [weak self] in
            guard let self else { throw CustomError.missingSelf }
            
            // If we need to insert an initial article, create or fetch existing CDPage of article.
            var page: CDPage?
            page = try self.pageForArticle(article, moc: moc)
            
            // If setting as current, first set all other tabs to not current
            if setAsCurrent {
                let predicate = NSPredicate(format: "isCurrent == YES")
                let currentTab = try coreDataStore.fetch(entityType: CDArticleTab.self, predicate: predicate, fetchLimit: 1, in: moc)?.first
                currentTab?.isCurrent = false
            }
            
            // Create CDArticleTab
            let newArticleTab = try coreDataStore.create(entityType: CDArticleTab.self, in: moc)
            newArticleTab.timestamp = Date()
            newArticleTab.isCurrent = setAsCurrent
            let tabIdentifier = UUID()
            newArticleTab.identifier = tabIdentifier
            
            // Create CDArticleTabItem and add to newArticleTab
            var tabItemIdentifier: UUID? = nil
            if let page {
                let articleTabItem = try self.newArticleTabItem(page: page, moc: moc)
                tabItemIdentifier = articleTabItem.identifier
                articleTabItem.isCurrent = true
                newArticleTab.items = NSOrderedSet(array: [articleTabItem])
            }
            
            try coreDataStore.saveIfNeeded(moc: moc)
            
            return Identifiers(tabIdentifier: tabIdentifier, tabItemIdentifier: tabItemIdentifier)
        }
    }
    
    public func deleteArticleTab(identifier: UUID) async throws {
        
        guard let coreDataStore else {
            throw WMFDataControllerError.coreDataStoreUnavailable
        }
        
        guard let moc = backgroundContext else {
            throw CustomError.missingContext
        }
        
        try await moc.perform { [weak self] in
            guard let self else { throw CustomError.missingSelf }

            try self.deleteArticleTab(identifier: identifier, moc: moc)
            try coreDataStore.saveIfNeeded(moc: moc)
        }
    }
    
    public func appendArticle(_ article: WMFArticle, toTabIdentifier tabIdentifier: UUID, needsCleanoutOfFutureArticles: Bool = false) async throws -> Identifiers {
        
        guard let coreDataStore else {
            throw WMFDataControllerError.coreDataStoreUnavailable
        }
        
        guard let moc = backgroundContext else {
            throw CustomError.missingContext
        }
        
        let result = try await moc.perform { [weak self] in
            guard let self else { throw CustomError.missingSelf }
            
            let tabPredicate = NSPredicate(format: "identifier == %@", argumentArray: [tabIdentifier])
            let tab = try coreDataStore.fetch(entityType: CDArticleTab.self, predicate: tabPredicate, fetchLimit: 1, in: moc)?.first
            
            guard let tab else {
                throw CustomError.missingTab
            }
            
            // Create a new tab item object for article
            let page = try self.pageForArticle(article, moc: moc)
            let newArticleTabItem = try self.newArticleTabItem(page: page, moc: moc)
            
            // Set tab's existing items' isCurrent values = false. Delete any additional articles after the current article.
            var newItems: [CDArticleTabItem] = []
            var foundCurrent: Bool = false
            if let currentItems = tab.items as? NSMutableOrderedSet {
                let safeCurrentItems = currentItems.compactMap { $0 as? CDArticleTabItem }
                for tabItem in safeCurrentItems {

                    if tabItem.isCurrent {
                        tabItem.isCurrent = false
                        newItems.append(tabItem)
                        foundCurrent = true
                    } else {
                        if foundCurrent && needsCleanoutOfFutureArticles {
                            moc.delete(tabItem)
                            
                            // Post notification
                            if let identifier = tabItem.identifier {
                                NotificationCenter.default.post(
                                    name: WMFNSNotification.articleTabItemDeleted,
                                    object: nil,
                                    userInfo: [WMFNSNotification.UserInfoKey.articleTabItemIdentifier: identifier]
                                )
                            }
                            
                            
                        } else {
                            newItems.append(tabItem)
                        }
                    }
                }
            }
            
            if let lastTabItem = newItems.last,
               lastTabItem.page == newArticleTabItem.page {
                // If tab's last item is the same article, set as isCurrent and don't append a duplicate tab item.
                lastTabItem.isCurrent = true
                moc.delete(newArticleTabItem)
            } else {
                // Set new tab item as current, append to tab's items
                newArticleTabItem.isCurrent = true
                newItems.append(newArticleTabItem)
            }
            
            tab.items = NSOrderedSet(array: newItems)
            
            guard let tabIdentifier = tab.identifier,
                  let tabItemIdentifier = newArticleTabItem.identifier else {
                throw CustomError.missingIdentifier
            }
            
            try coreDataStore.saveIfNeeded(moc: moc)
            
            return Identifiers(tabIdentifier: tabIdentifier, tabItemIdentifier: tabItemIdentifier)
        }
        
        return result
    }
    
    public func getAdjacentArticleInTab(tabIdentifier: UUID, isPrev: Bool) async throws -> WMFArticle? {
        guard let moc = backgroundContext else {
            throw CustomError.missingContext
        }
        
        guard let coreDataStore else {
            throw WMFDataControllerError.coreDataStoreUnavailable
        }
        
        let block: () throws -> WMFArticle? = {
            let predicate = NSPredicate(format: "identifier == %@", argumentArray: [tabIdentifier])
            
            guard let tab = try coreDataStore.fetch(entityType: CDArticleTab.self, predicate: predicate, fetchLimit: 1, in: moc)?.first else {
                throw CustomError.missingTab
            }
            
            guard let items = tab.items as? NSMutableOrderedSet, items.count > 0 else {
                throw CustomError.missingPage
            }
            
            var adjacentArticle: Any?
            for (index, item) in items.enumerated() {
                guard let articleItem = item as? CDArticleTabItem else { continue }

                if articleItem.isCurrent {
                    if isPrev,
                        (index - 1) >= 0,
                        items.count > index - 1 {
                        adjacentArticle = items[index - 1]
                        break
                    } else if
                        !isPrev,
                        (index + 1) >= 0,
                        items.count > index + 1 {
                        adjacentArticle = items[index + 1]
                        break
                    }
                }
            }
            
            if let cdArticleItem = adjacentArticle as? CDArticleTabItem,
               let title = cdArticleItem.page?.title,
               let identifier = cdArticleItem.identifier,
               let coreDataIdentifier = cdArticleItem.page?.projectID,
               let wmfProject = WMFProject(coreDataIdentifier: coreDataIdentifier) {
                let wmfArticle = WMFArticle(identifier: identifier, title: title, project: wmfProject)
                return wmfArticle
            }
            
            return nil
        }
        
        let result: WMFArticle? = try await moc.perform(block)
        return result
            
    }
    
    public func setTabItemAsCurrent(tabIdentifier: UUID, tabItemIdentifier: UUID) async throws {
        
        guard let coreDataStore else {
            throw WMFDataControllerError.coreDataStoreUnavailable
        }
        
        guard let moc = backgroundContext else {
            throw CustomError.missingContext
        }
        
        try await moc.perform { [weak self] in
            guard let self else { throw CustomError.missingSelf }
            
            let predicate = NSPredicate(format: "identifier == %@", argumentArray: [tabIdentifier])
            
            guard let tab = try coreDataStore.fetch(entityType: CDArticleTab.self, predicate: predicate, fetchLimit: 1, in: moc)?.first else {
                throw CustomError.missingTab
            }
            
            guard let items = tab.items as? NSMutableOrderedSet, items.count > 0 else {
                throw CustomError.missingPage
            }
            
            let articleItems = items.compactMap { $0 as? CDArticleTabItem }
            for articleItem in articleItems {
                if articleItem.identifier == tabItemIdentifier {
                    articleItem.isCurrent = true
                } else {
                    articleItem.isCurrent = false
                }
            }
            
            try setTabAsCurrent(tabIdentifier: tabIdentifier, moc: moc)
            
            try coreDataStore.saveIfNeeded(moc: moc)
        }
    }
    
    public func deleteEmptyTabs() async throws {
        
        guard let coreDataStore else {
            throw WMFDataControllerError.coreDataStoreUnavailable
        }
        
        guard let moc = backgroundContext else {
            throw CustomError.missingContext
        }
        
        try await moc.perform { [weak self] in
            guard let self else { throw CustomError.missingSelf }
            
            let predicate = NSPredicate(format: "items.@count == 0")
            
            guard let tabs = try coreDataStore.fetch(entityType: CDArticleTab.self, predicate: predicate, fetchLimit: nil, in: moc) else {
                throw CustomError.missingTab
            }
            
            for tab in tabs {
                guard let tabIdentifier = tab.identifier else { continue }
                try self.deleteArticleTab(identifier: tabIdentifier, moc: moc)
            }
            
            try coreDataStore.saveIfNeeded(moc: moc)
        }
    }
    
    public func updateSurveyDataTabsOverviewSeenCount() {
        var seenCount: Int = (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.articleTabsOverviewOpenedCount.rawValue)) ?? 0
        
        seenCount += 1
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.articleTabsOverviewOpenedCount.rawValue, value: seenCount)
    }
    
    public func updateSurveyDataTappedLongPressFlag() {
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.articleTabsDidTapOpenInNewTab.rawValue, value: true)
    }
    
    public func shouldShowSurvey() -> Bool {
        // Make sure it's before July 31, 2025
        let now = Date()
        let calendar = Calendar.current
        let deadlineComponents = DateComponents(year: 2025, month: 7, day: 31)

        guard let deadline = calendar.date(from: deadlineComponents),
              now <= deadline else {
            return false
        }
        
        let seenCount: Int = (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.articleTabsOverviewOpenedCount.rawValue)) ?? 0
        let didTapLongPress = (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.articleTabsDidTapOpenInNewTab.rawValue)) ?? false
        let seenSurvey = (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.articleTabsDidShowSurvey.rawValue)) ?? false

        if seenSurvey {
            return false
        }
        
        if seenCount >= 3 && didTapLongPress {
            try? userDefaultsStore?.save(key: WMFUserDefaultsKey.articleTabsDidShowSurvey.rawValue, value: true)
            return true
        }
        
        return false
    }
    
    public func didTapOpenNewTab() {
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.articleTabsDidTapOpenInNewTab.rawValue, value: true)
    }
    
    // MARK: - Private funcs
    
    private func pageForArticle(_ article: WMFArticle, moc: NSManagedObjectContext) throws -> CDPage {
        
        guard let coreDataStore else {
            throw WMFDataControllerError.coreDataStoreUnavailable
        }
        
        let coreDataTitle = article.title.normalizedForCoreData
        let pagePredicate = NSPredicate(format: "projectID == %@ && namespaceID == %@ && title == %@", argumentArray: [article.project.coreDataIdentifier, 0, coreDataTitle])
        
        let page = try coreDataStore.fetchOrCreate(entityType: CDPage.self, predicate: pagePredicate, in: moc)
        
        guard let page else {
            throw CustomError.missingPage
        }
        
        page.title = coreDataTitle
        page.namespaceID = 0
        page.projectID = article.project.coreDataIdentifier
        if page.timestamp == nil {
            page.timestamp = Date()
        }
        
        return page
    }
    
    private func newArticleTabItem(page: CDPage, moc: NSManagedObjectContext) throws -> CDArticleTabItem {
        
        guard let coreDataStore else {
            throw WMFDataControllerError.coreDataStoreUnavailable
        }
        
        let newArticleTabItem = try coreDataStore.create(entityType: CDArticleTabItem.self, in: moc)
        newArticleTabItem.page = page
        newArticleTabItem.identifier = UUID()
        return newArticleTabItem
    }
    
    private func tabsCount(moc: NSManagedObjectContext) throws -> Int {
        let fetchRequest = NSFetchRequest<CDArticleTab>(entityName: "CDArticleTab")
        return try moc.count(for: fetchRequest)
    }
    
    private func deleteArticleTab(identifier: UUID, moc: NSManagedObjectContext) throws {
        guard let coreDataStore else {
            throw WMFDataControllerError.coreDataStoreUnavailable
        }
        
        let tabsCount = try tabsCount(moc: moc)
        
        if tabsCount <= 1 {
            throw CustomError.cannotDeleteLastTab
        }
        
        let predicate = NSPredicate(format: "identifier == %@", argumentArray: [identifier])
        
        guard let articleTab = try coreDataStore.fetch(entityType: CDArticleTab.self, predicate: predicate, fetchLimit: 1, in: moc)?.first else {
            throw CustomError.missingTab
        }
        
        let wasCurrent = articleTab.isCurrent
        if let items = articleTab.items {
            
            // Make a copy so we're not mutating while iterating
            let safeItems = items.compactMap { $0 as? CDArticleTabItem }
            
            for item in safeItems {
                item.tab = nil
                moc.delete(item)
            }
        }
        
        moc.delete(articleTab)
        
        // If we deleted the current tab, find the next most recent tab to set as current
        if wasCurrent {
            let fetchRequest = NSFetchRequest<CDArticleTab>(entityName: "CDArticleTab")
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
            if let nextTab = try moc.fetch(fetchRequest).first {
                nextTab.isCurrent = true
            }
        }
        
        // Post notification
        NotificationCenter.default.post(
            name: WMFNSNotification.articleTabDeleted,
            object: nil,
            userInfo: [WMFNSNotification.UserInfoKey.articleTabIdentifier: identifier]
        )
    }
    
    public func currentTabIdentifier() async throws -> UUID {
        
        guard let coreDataStore else {
            throw WMFDataControllerError.coreDataStoreUnavailable
        }
        
        guard let moc = backgroundContext else {
            throw CustomError.missingContext
        }
        
        return try await moc.perform {
            let predicate = NSPredicate(format: "isCurrent == YES")
            guard let currentTab = try coreDataStore.fetch(entityType: CDArticleTab.self, predicate: predicate, fetchLimit: 1, in: moc)?.first,
                  let identifier = currentTab.identifier else {
                throw CustomError.missingTab
            }
            return identifier
        }
    }
    
    public func setTabAsCurrent(tabIdentifier: UUID) async throws {
        
        guard let coreDataStore else {
            throw WMFDataControllerError.coreDataStoreUnavailable
        }
        
        guard let moc = backgroundContext else {
            throw CustomError.missingContext
        }
        
        try await moc.perform { [weak self] in
            guard let self else { throw CustomError.missingSelf }
            try self.setTabAsCurrent(tabIdentifier: tabIdentifier, moc: moc)
            
            try coreDataStore.saveIfNeeded(moc: moc)
        }
    }
    
    private func setTabAsCurrent(tabIdentifier: UUID, moc: NSManagedObjectContext) throws {
        
        guard let coreDataStore else {
            throw WMFDataControllerError.coreDataStoreUnavailable
        }
        
        // First set all other tabs to not current
        let currentPredicate = NSPredicate(format: "isCurrent == YES")
        if let currentTab = try coreDataStore.fetch(entityType: CDArticleTab.self, predicate: currentPredicate, fetchLimit: 1, in: moc)?.first {
            currentTab.isCurrent = false
        }
        
        // Then set the specified tab as current
        let tabPredicate = NSPredicate(format: "identifier == %@", argumentArray: [tabIdentifier])
        guard let tab = try coreDataStore.fetch(entityType: CDArticleTab.self, predicate: tabPredicate, fetchLimit: 1, in: moc)?.first else {
            throw CustomError.missingTab
        }
        
        tab.isCurrent = true
    }
    
    public func fetchAllArticleTabs() async throws -> [WMFArticleTab] {
        
        guard let coreDataStore else {
            throw WMFDataControllerError.coreDataStoreUnavailable
        }
        
        guard let moc = backgroundContext else {
            throw CustomError.missingContext
        }
        
        let databaseTabs = try await moc.perform {
            guard let cdArticleTabs = try coreDataStore.fetch(entityType: CDArticleTab.self, predicate: nil, fetchLimit: nil, in: moc) else {
                throw CustomError.missingTab
            }
            
            var articleTabs: [WMFArticleTab] = []
            
            for cdTab in cdArticleTabs {
                guard let tabIdentifier = cdTab.identifier else {
                    continue
                }
                
                guard let timestamp = cdTab.timestamp else {
                    continue
                }
                
                var articles: [WMFArticle] = []
                
                guard let items = cdTab.items else {
                    continue
                }
                
                for item in items {
                    guard let articleTabItem = item as? CDArticleTabItem,
                          let page = articleTabItem.page,
                          let identifier = articleTabItem.identifier,
                          let title = page.title,
                          let projectID = page.projectID,
                          let project = WMFProject(coreDataIdentifier: projectID) else {
                        throw CustomError.unexpectedType
                    }
                    
                    let article = WMFArticle(identifier: identifier, title: title, project: project)
                    articles.append(article)
                    
                    // don't append any more after current article.
                    if articleTabItem.isCurrent {
                        break
                    }
                }
                
                let articleTab = WMFArticleTab(identifier: tabIdentifier, timestamp: timestamp, isCurrent: cdTab.isCurrent, articles: articles)
                articleTabs.append(articleTab)
            }
            
            return articleTabs
        }
        
        return databaseTabs
    }
    
    public func saveCurrentStateForLaterRestoration() async throws {
        
        guard let coreDataStore else {
            throw WMFDataControllerError.coreDataStoreUnavailable
        }

        guard let moc = backgroundContext else {
            throw CustomError.missingContext
        }

       try await moc.perform { [weak self] in
            guard let self else { return }
            let currentPredicate = NSPredicate(format: "isCurrent == YES")
            guard let cdTab = try coreDataStore.fetch(entityType: CDArticleTab.self, predicate: currentPredicate, fetchLimit: 1, in: moc)?.first,
            let tabIdentifier = cdTab.identifier,
            let tabTimestamp = cdTab.timestamp else {
                throw CustomError.missingTab
            }
            
            let cdItems = cdTab.items?.compactMap { $0 as? CDArticleTabItem }
           let cdItem = cdItems?.first(where: { $0.isCurrent == true })
           guard let cdItem,
                let articleIdentifier = cdItem.identifier,
                let page = cdItem.page,
                let title = page.title,
                let projectID = page.projectID,
                 let project = WMFProject(coreDataIdentifier: projectID) else {
                throw CustomError.missingTabItem
            }
            
           let tab = WMFArticleTab(identifier: tabIdentifier, timestamp: tabTimestamp, isCurrent: cdTab.isCurrent, articles: [WMFArticle(identifier: articleIdentifier, title: title, project: project)])
           
           try userDefaultsStore?.save(key: WMFUserDefaultsKey.articleTabRestoration.rawValue, value: tab)
        }
    }
    
    
    public func loadCurrentStateForRestoration() throws -> WMFArticleTab? {
        let result: WMFArticleTab? = try userDefaultsStore?.load(key: WMFUserDefaultsKey.articleTabRestoration.rawValue)
        return result
    }
    
    public func clearCurrentStateForRestoration() throws {
        try userDefaultsStore?.remove(key: WMFUserDefaultsKey.articleTabRestoration.rawValue)
    }
}

private extension WMFProject {
    var qualifiesForExperiment: Bool {
        switch self {
        case .wikipedia(let language):
            return language.languageCode.lowercased() == "en" || language.languageCode.lowercased() == "ar" || language.languageCode.lowercased() == "de"
        case .wikidata:
            return false
        case .commons:
            return false
        }
    }
}

private extension Locale {
    var qualifiesForExperiment: Bool {
        guard let identifier = region?.identifier.lowercased() else {
            return false
        }
        switch identifier {
        case "au", "hk", "id", "jp", "my", "mm", "nz", "ph", "sg", "kr", "tw", "th", "vn": // eseap
            return true
        case "dz", "bh", "eg", "jo", "kw", "lb", "ly", "ma", "om", "qa", "sa", "tn", "ae", "ye": // mena
            return true
        case "de": // germany
            return true
        default:
            return false
        }
    }
}

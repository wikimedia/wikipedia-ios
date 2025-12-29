import Foundation
import UIKit
@preconcurrency import CoreData

public protocol WMFArticleTabsDataControlling {
    func tabsCount() async throws -> Int
    func createArticleTab(initialArticle: WMFArticleTabsDataController.WMFArticle?, setAsCurrent: Bool) async throws -> WMFArticleTabsDataController.Identifiers
    func deleteArticleTab(identifier: UUID) async throws
    func appendArticle(_ article: WMFArticleTabsDataController.WMFArticle, toTabIdentifier identifier: UUID, needsCleanoutOfFutureArticles: Bool) async throws -> WMFArticleTabsDataController.Identifiers
    func setTabItemAsCurrent(tabIdentifier: UUID, tabItemIdentifier: UUID) async throws
    func setTabAsCurrent(tabIdentifier: UUID) async throws
    func currentTabIdentifier() async throws -> UUID?
    func fetchAllArticleTabs() async throws -> [WMFArticleTabsDataController.WMFArticleTab]
}

// MARK: - Pure Swift Actor

public actor WMFArticleTabsDataController: WMFArticleTabsDataControlling {
    
    public enum CustomError: Error {
        case missingTab, missingTabItem, missingSelf, cannotDeleteLastTab, missingPage
        case unexpectedType, missingIdentifier, missingTimestamp, missingContext
        case missingAppLanguage, missingExperimentsDataController, unexpectedAssignment
        case missingAssignment, doesNotQualifyForExperiment, alreadyAssignedExperiment
        case pastAssignmentEndDate, missingURL
    }
    
    public struct WMFArticle: Codable, Sendable {
        public let identifier: UUID?, title: String, description: String?, extract: String?
        public let imageURL: URL?, project: WMFProject, articleURL: URL?

        public init(identifier: UUID?, title: String, description: String? = nil, extract: String? = nil, imageURL: URL? = nil, project: WMFProject, articleURL: URL?) {
            self.identifier = identifier; self.title = title; self.description = description
            self.extract = extract; self.imageURL = imageURL; self.project = project; self.articleURL = articleURL
        }
        
        public var isMain: Bool { title == "Main_Page" || title == "Main Page" }
    }
    
    public struct WMFArticleTab: Codable, Equatable, Sendable {
        public let identifier: UUID, timestamp: Date, isCurrent: Bool, articles: [WMFArticle]
        public init(identifier: UUID, timestamp: Date, isCurrent: Bool, articles: [WMFArticle]) {
            self.identifier = identifier; self.timestamp = timestamp; self.isCurrent = isCurrent; self.articles = articles
        }
        public static func == (lhs: WMFArticleTab, rhs: WMFArticleTab) -> Bool { lhs.identifier == rhs.identifier }
    }
    
    public struct Identifiers: Sendable {
        public let tabIdentifier: UUID, tabItemIdentifier: UUID?
        public init(tabIdentifier: UUID, tabItemIdentifier: UUID?) {
            self.tabIdentifier = tabIdentifier; self.tabItemIdentifier = tabItemIdentifier
        }
    }
    
    public enum MoreDynamicTabsExperimentAssignment { case groupC }
    struct OnboardingStatus: Codable {
        var hasPresentedOnboardingTooltips: Bool
        static var `default`: OnboardingStatus { OnboardingStatus(hasPresentedOnboardingTooltips: false) }
    }

    public static let shared = WMFArticleTabsDataController()
    private let userDefaultsStore = WMFDataEnvironment.current.userDefaultsStore
    private let developerSettingsDataController: WMFDeveloperSettingsDataController
    private let experimentsDataController: WMFExperimentsDataController?
    private var assignmentCache: MoreDynamicTabsExperimentAssignment?
    private let moreDynamicTabsExperimentPercentage: Int = 33
    private var _backgroundContext: NSManagedObjectContext?
    
    public var backgroundContext: NSManagedObjectContext? {
        get {
            if _backgroundContext == nil {
                _backgroundContext = try? coreDataStore?.newBackgroundContext
                _backgroundContext?.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
            }
            return _backgroundContext
        }
        set { _backgroundContext = newValue }
    }
    
    private var _coreDataStore: WMFCoreDataStore?
    private var coreDataStore: WMFCoreDataStore? { _coreDataStore ?? WMFDataEnvironment.current.coreDataStore }

    public var userHasHiddenArticleSuggestionsTabs: Bool {
        (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.userHasHiddenArticleSuggestionsTabs.rawValue)) ?? false
    }
    
    public func setUserHasHiddenArticleSuggestionsTabs(_ value: Bool) {
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.userHasHiddenArticleSuggestionsTabs.rawValue, value: value)
    }
    
    public init(coreDataStore: WMFCoreDataStore? = WMFDataEnvironment.current.coreDataStore,
                developerSettingsDataController: WMFDeveloperSettingsDataController = .shared,
                experimentStore: WMFKeyValueStore? = WMFDataEnvironment.current.sharedCacheStore) {
        self._coreDataStore = coreDataStore
        self.developerSettingsDataController = developerSettingsDataController
        self.experimentsDataController = experimentStore != nil ? WMFExperimentsDataController(store: experimentStore!) : nil
    }
    
    private func shouldAssignToBucketV2() -> Bool { experimentsDataController?.bucketForExperimentSyncBridge(.moreDynamicTabsV2) == nil }
    public var shouldShowMoreDynamicTabsV2: Bool { true }
    private var primaryAppLanguageProject: WMFProject? {
        guard let language = WMFDataEnvironment.current.appData.appLanguages.first else { return nil }
        return WMFProject.wikipedia(language)
    }
    
    private var isBeforeAssignmentEndDate: Bool {
        var dc = DateComponents(); dc.year = 2026; dc.month = 1; dc.day = 15
        guard let endDate = Calendar.current.date(from: dc) else { return false }
        return endDate >= Date()
    }
    
    private func qualifiesForExperiment() -> Bool {
        guard let proj = primaryAppLanguageProject else { return false }
        return Locale.current.qualifiesForExperiment && proj.qualifiesForExperiment
    }

    public func getMoreDynamicTabsExperimentAssignmentV2() throws -> MoreDynamicTabsExperimentAssignment {
        guard qualifiesForExperiment() else { throw CustomError.doesNotQualifyForExperiment }
        let assignment: MoreDynamicTabsExperimentAssignment = .groupC
        self.assignmentCache = assignment
        return assignment
    }
    
    public func assignExperimentV2IfNeeded() throws -> MoreDynamicTabsExperimentAssignment {
        guard qualifiesForExperiment() else { throw CustomError.doesNotQualifyForExperiment }
        guard isBeforeAssignmentEndDate else { throw CustomError.pastAssignmentEndDate }
        let assignment: MoreDynamicTabsExperimentAssignment = .groupC
        self.assignmentCache = assignment
        return assignment
    }

    public var moreDynamicTabsGroupCEnabled: Bool { true }
    
    internal var onboardingStatus: OnboardingStatus {
        (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.articleTabsOnboarding.rawValue)) ?? OnboardingStatus.default
    }
    
    public var hasPresentedTooltips: Bool { onboardingStatus.hasPresentedOnboardingTooltips }
    
    public func setHasPresentedTooltips(_ value: Bool) {
        var currentStatus = onboardingStatus
        currentStatus.hasPresentedOnboardingTooltips = value
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.articleTabsOnboarding.rawValue, value: currentStatus)
    }
    
    public func tabsCount() async throws -> Int {
        guard let moc = backgroundContext else { throw CustomError.missingContext }
        return try await moc.perform {
            let fr = NSFetchRequest<CDArticleTab>(entityName: "CDArticleTab")
            return try moc.count(for: fr)
        }
    }
    
    public var tabsMax: Int {
        get async { await developerSettingsDataController.forceMaxArticleTabsTo5 ? 5 : 500 }
    }

    public func createArticleTab(initialArticle: WMFArticle?, setAsCurrent: Bool = false) async throws -> Identifiers {
        guard let coreDataStore else { throw WMFDataControllerError.coreDataStoreUnavailable }
        guard let moc = backgroundContext else { throw CustomError.missingContext }
        
        let article: WMFArticle
        if let initialArticle {
            article = initialArticle
        } else {
            guard let lang = WMFDataEnvironment.current.appData.appLanguages.first else { throw CustomError.missingAppLanguage }
            let proj = WMFProject.wikipedia(lang)
            let title = "Main_Page"
            guard let siteURL = proj.siteURL, let articleURL = siteURL.wmfURL(withTitle: title, languageVariantCode: nil) else {
                throw CustomError.missingURL
            }
            article = WMFArticle(identifier: nil, title: title, project: proj, articleURL: articleURL)
        }

        let store = coreDataStore
        return try await withCheckedThrowingContinuation { continuation in
            moc.perform { [self] in
                do {
                    let page: CDPage? = try self.pageForArticle(article, moc: moc, coreDataStore: store)
                    
                    if setAsCurrent {
                        let pred = NSPredicate(format: "isCurrent == YES")
                        let currTab = try store.fetch(entityType: CDArticleTab.self, predicate: pred, fetchLimit: 1, in: moc)?.first
                        currTab?.isCurrent = false
                    }
                    
                    let newTab = try store.create(entityType: CDArticleTab.self, in: moc)
                    newTab.timestamp = Date()
                    newTab.isCurrent = setAsCurrent
                    let tabID = UUID()
                    newTab.identifier = tabID
                    
                    var tabItemID: UUID? = nil
                    if let page {
                        let item = try self.newArticleTabItem(page: page, moc: moc, coreDataStore: store)
                        tabItemID = item.identifier
                        item.isCurrent = true
                        newTab.items = NSOrderedSet(array: [item])
                    }
                    
                    try store.saveIfNeeded(moc: moc)
                    continuation.resume(returning: Identifiers(tabIdentifier: tabID, tabItemIdentifier: tabItemID))
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    public func deleteArticleTab(identifier: UUID) async throws {
        guard let coreDataStore else { throw WMFDataControllerError.coreDataStoreUnavailable }
        guard let moc = backgroundContext else { throw CustomError.missingContext }
        
        let store = coreDataStore
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            moc.perform { [self] in
                do {
                    try self.deleteArticleTab(identifier: identifier, moc: moc)
                    try store.saveIfNeeded(moc: moc)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    public func deleteAllTabs() async throws {
        guard let moc = backgroundContext else { throw CustomError.missingContext }
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            moc.perform { [self] in
                do {
                    try self.deleteAllTabs(moc: moc)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    public func appendArticle(_ article: WMFArticle, toTabIdentifier tabID: UUID, needsCleanoutOfFutureArticles: Bool = false) async throws -> Identifiers {
        guard let coreDataStore else { throw WMFDataControllerError.coreDataStoreUnavailable }
        guard let moc = backgroundContext else { throw CustomError.missingContext }
        
        let store = coreDataStore
        return try await withCheckedThrowingContinuation { continuation in
            moc.perform { [self] in
                do {
                    let pred = NSPredicate(format: "identifier == %@", argumentArray: [tabID])
                    guard let tab = try store.fetch(entityType: CDArticleTab.self, predicate: pred, fetchLimit: 1, in: moc)?.first else {
                        throw CustomError.missingTab
                    }
                    
                    let page = try self.pageForArticle(article, moc: moc, coreDataStore: store)
                    let newItem = try self.newArticleTabItem(page: page, moc: moc, coreDataStore: store)
                    
                    var newItems: [CDArticleTabItem] = []
                    var foundCurr: Bool = false
                    if let currItems = tab.items as? NSMutableOrderedSet {
                        let safe = currItems.compactMap { $0 as? CDArticleTabItem }
                        for ti in safe {
                            if ti.isCurrent {
                                ti.isCurrent = false
                                newItems.append(ti)
                                foundCurr = true
                            } else {
                                if foundCurr && needsCleanoutOfFutureArticles {
                                    moc.delete(ti)
                                    if let id = ti.identifier {
                                        NotificationCenter.default.post(name: WMFNSNotification.articleTabItemDeleted, object: nil,
                                                                      userInfo: [WMFNSNotification.UserInfoKey.articleTabItemIdentifier: id])
                                    }
                                } else {
                                    newItems.append(ti)
                                }
                            }
                        }
                    }
                    
                    if let last = newItems.last, last.page == newItem.page {
                        last.isCurrent = true
                        moc.delete(newItem)
                    } else {
                        newItem.isCurrent = true
                        newItems.append(newItem)
                    }
                    
                    tab.items = NSOrderedSet(array: newItems)
                    guard let tid = tab.identifier, let tiid = newItem.identifier else { throw CustomError.missingIdentifier }
                    try store.saveIfNeeded(moc: moc)
                    continuation.resume(returning: Identifiers(tabIdentifier: tid, tabItemIdentifier: tiid))
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    public func getAdjacentArticleInTab(tabIdentifier: UUID, isPrev: Bool) async throws -> WMFArticle? {
        guard let moc = backgroundContext, let coreDataStore else { throw CustomError.missingContext }
        
        let store = coreDataStore
        return try await withCheckedThrowingContinuation { continuation in
            moc.perform {
                do {
                    let pred = NSPredicate(format: "identifier == %@", argumentArray: [tabIdentifier])
                    guard let tab = try store.fetch(entityType: CDArticleTab.self, predicate: pred, fetchLimit: 1, in: moc)?.first,
                          let items = tab.items as? NSMutableOrderedSet, items.count > 0 else { throw CustomError.missingTab }
                    
                    var adj: Any?
                    for (i, item) in items.enumerated() {
                        guard let ai = item as? CDArticleTabItem, ai.isCurrent else { continue }
                        if isPrev, i - 1 >= 0, items.count > i - 1 { adj = items[i - 1]; break } else if !isPrev, i + 1 >= 0, items.count > i + 1 { adj = items[i + 1]; break }
                    }

                    if let cdi = adj as? CDArticleTabItem, let t = cdi.page?.title, let id = cdi.identifier,
                       let pid = cdi.page?.projectID, let proj = WMFProject(id: pid),
                       let siteURL = proj.siteURL, let aurl = siteURL.wmfURL(withTitle: t, languageVariantCode: nil) {
                        continuation.resume(returning: WMFArticle(identifier: id, title: t, project: proj, articleURL: aurl))
                    } else {
                        continuation.resume(returning: nil)
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    public func setTabItemAsCurrent(tabIdentifier: UUID, tabItemIdentifier: UUID) async throws {
        guard let coreDataStore else { throw WMFDataControllerError.coreDataStoreUnavailable }
        guard let moc = backgroundContext else { throw CustomError.missingContext }
        
        let store = coreDataStore
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            moc.perform { [self] in
                do {
                    let pred = NSPredicate(format: "identifier == %@", argumentArray: [tabIdentifier])
                    guard let tab = try store.fetch(entityType: CDArticleTab.self, predicate: pred, fetchLimit: 1, in: moc)?.first,
                          let items = tab.items as? NSMutableOrderedSet, items.count > 0 else { throw CustomError.missingTab }
                    
                    let ais = items.compactMap { $0 as? CDArticleTabItem }
                    for ai in ais { ai.isCurrent = ai.identifier == tabItemIdentifier }
                    try self.setTabAsCurrent(tabIdentifier: tabIdentifier, moc: moc)
                    try store.saveIfNeeded(moc: moc)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    public func deleteEmptyTabs() async throws {
        guard let coreDataStore, let moc = backgroundContext else { throw CustomError.missingContext }
        
        let store = coreDataStore
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            moc.perform { [self] in
                do {
                    let pred = NSPredicate(format: "items.@count == 0")
                    guard let tabs = try store.fetch(entityType: CDArticleTab.self, predicate: pred, fetchLimit: nil, in: moc) else {
                        throw CustomError.missingTab
                    }
                    for tab in tabs {
                        guard let tid = tab.identifier else { continue }
                        try self.deleteArticleTab(identifier: tid, moc: moc)
                    }
                    try store.saveIfNeeded(moc: moc)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    public func updateSurveyDataTabsOverviewSeenCount() {
        var sc: Int = (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.articleTabsOverviewOpenedCountBandC.rawValue)) ?? 0
        sc += 1
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.articleTabsOverviewOpenedCountBandC.rawValue, value: sc)
    }

    public func updateSurveyDataTappedLongPressFlag() {
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.articleTabsDidTapOpenInNewTab.rawValue, value: true)
    }
    
    public func didTapOpenNewTab() {
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.articleTabsDidTapOpenInNewTab.rawValue, value: true)
    }
    
    private func pageForArticle(_ article: WMFArticle, moc: NSManagedObjectContext, coreDataStore: WMFCoreDataStore) throws -> CDPage {
        let cdt = article.title.normalizedForCoreData
        let pred = NSPredicate(format: "projectID == %@ && namespaceID == %@ && title == %@",
                             argumentArray: [article.project.id, 0, cdt])
        guard let page = try coreDataStore.fetchOrCreate(entityType: CDPage.self, predicate: pred, in: moc) else {
            throw CustomError.missingPage
        }
        page.title = cdt; page.namespaceID = 0; page.projectID = article.project.id
        if page.timestamp == nil { page.timestamp = Date() }
        return page
    }
    
    private func newArticleTabItem(page: CDPage, moc: NSManagedObjectContext, coreDataStore: WMFCoreDataStore) throws -> CDArticleTabItem {
        let item = try coreDataStore.create(entityType: CDArticleTabItem.self, in: moc)
        item.page = page; item.identifier = UUID()
        return item
    }
    
    private func tabsCount(moc: NSManagedObjectContext) throws -> Int {
        let fr = NSFetchRequest<CDArticleTab>(entityName: "CDArticleTab")
        return try moc.count(for: fr)
    }
    
    private func deleteArticleTab(identifier: UUID, moc: NSManagedObjectContext) throws {
        guard let coreDataStore else { throw WMFDataControllerError.coreDataStoreUnavailable }
        let tc = try tabsCount(moc: moc)
        if tc <= 1 && !shouldShowMoreDynamicTabsV2 { throw CustomError.cannotDeleteLastTab }
        
        let pred = NSPredicate(format: "identifier == %@", argumentArray: [identifier])
        guard let at = try coreDataStore.fetch(entityType: CDArticleTab.self, predicate: pred, fetchLimit: 1, in: moc)?.first else {
            throw CustomError.missingTab
        }
        
        let wc = at.isCurrent
        if let items = at.items {
            let safe = items.compactMap { $0 as? CDArticleTabItem }
            for item in safe { item.tab = nil; moc.delete(item) }
        }
        moc.delete(at)
        
        if wc {
            let fr = NSFetchRequest<CDArticleTab>(entityName: "CDArticleTab")
            fr.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
            if let next = try moc.fetch(fr).first { next.isCurrent = true }
        }
        
        NotificationCenter.default.post(name: WMFNSNotification.articleTabDeleted, object: nil,
                                      userInfo: [WMFNSNotification.UserInfoKey.articleTabIdentifier: identifier])
    }
    
    private func deleteAllTabs(moc: NSManagedObjectContext) throws {
        guard let coreDataStore else { throw WMFDataControllerError.coreDataStoreUnavailable }
        let tabs = try coreDataStore.fetch(entityType: CDArticleTab.self, predicate: nil, fetchLimit: nil, in: moc) ?? []
        if tabs.isEmpty { return }
        
        for tab in tabs {
            guard let id = tab.identifier else { return }
            NotificationCenter.default.post(name: WMFNSNotification.articleTabDeleted, object: nil,
                                          userInfo: [WMFNSNotification.UserInfoKey.articleTabIdentifier: id])
            if let items = tab.items {
                let safe = items.compactMap { $0 as? CDArticleTabItem }
                for item in safe { item.tab = nil; moc.delete(item) }
            }
            moc.delete(tab)
        }
        try coreDataStore.saveIfNeeded(moc: moc)
    }
    
    public func currentTabIdentifier() async throws -> UUID? {
        guard let coreDataStore, let moc = backgroundContext else { throw CustomError.missingContext }
        return try await fetchCurrentTabID(coreDataStore: coreDataStore, moc: moc)
    }

    private func fetchCurrentTabID(coreDataStore: WMFCoreDataStore, moc: NSManagedObjectContext) async throws -> UUID? {
        try await withCheckedThrowingContinuation { continuation in
            moc.perform {
                do {
                    let pred = NSPredicate(format: "isCurrent == YES")
                    let identifier = try coreDataStore.fetch(entityType: CDArticleTab.self, predicate: pred, fetchLimit: 1, in: moc)?.first?.identifier
                    continuation.resume(returning: identifier)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    public func setTabAsCurrent(tabIdentifier: UUID) async throws {
        guard let coreDataStore, let moc = backgroundContext else { throw CustomError.missingContext }
        
        let store = coreDataStore
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            moc.perform { [self] in
                do {
                    try self.setTabAsCurrent(tabIdentifier: tabIdentifier, moc: moc)
                    try store.saveIfNeeded(moc: moc)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func setTabAsCurrent(tabIdentifier: UUID, moc: NSManagedObjectContext) throws {
        guard let coreDataStore else { throw WMFDataControllerError.coreDataStoreUnavailable }
        let cp = NSPredicate(format: "isCurrent == YES")
        if let ct = try coreDataStore.fetch(entityType: CDArticleTab.self, predicate: cp, fetchLimit: 1, in: moc)?.first {
            ct.isCurrent = false
        }
        let tp = NSPredicate(format: "identifier == %@", argumentArray: [tabIdentifier])
        guard let tab = try coreDataStore.fetch(entityType: CDArticleTab.self, predicate: tp, fetchLimit: 1, in: moc)?.first else {
            throw CustomError.missingTab
        }
        tab.isCurrent = true
    }
    
    public func fetchAllArticleTabs() async throws -> [WMFArticleTab] {
        guard let coreDataStore, let moc = backgroundContext else { throw CustomError.missingContext }
        
        let store = coreDataStore
        return try await withCheckedThrowingContinuation { continuation in
            moc.perform {
                do {
                    guard let cdTabs = try store.fetch(entityType: CDArticleTab.self, predicate: nil, fetchLimit: nil, in: moc) else {
                        throw CustomError.missingTab
                    }
                    
                    var ats: [WMFArticleTab] = []
                    for cdt in cdTabs {
                        guard let tid = cdt.identifier, let ts = cdt.timestamp, let items = cdt.items else { continue }
                        var arts: [WMFArticle] = []
                        for item in items {
                            guard let ati = item as? CDArticleTabItem, let page = ati.page, let id = ati.identifier,
                                  let t = page.title, let pid = page.projectID, let proj = WMFProject(id: pid),
                                  let siteURL = proj.siteURL, let aurl = siteURL.wmfURL(withTitle: t, languageVariantCode: nil) else {
                                throw CustomError.unexpectedType
                            }
                            arts.append(WMFArticle(identifier: id, title: t, project: proj, articleURL: aurl))
                            if ati.isCurrent { break }
                        }
                        ats.append(WMFArticleTab(identifier: tid, timestamp: ts, isCurrent: cdt.isCurrent, articles: arts))
                    }
                    continuation.resume(returning: ats)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    public func saveCurrentStateForLaterRestoration() async throws {
        guard let coreDataStore, let moc = backgroundContext else { throw CustomError.missingContext }
        
        let store = coreDataStore
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            moc.perform { [self] in
                do {
                    let cp = NSPredicate(format: "isCurrent == YES")
                    guard let cdt = try store.fetch(entityType: CDArticleTab.self, predicate: cp, fetchLimit: 1, in: moc)?.first,
                          let tid = cdt.identifier, let tts = cdt.timestamp else { throw CustomError.missingTab }
                    
                    let cdis = cdt.items?.compactMap { $0 as? CDArticleTabItem }
                    let cdi = cdis?.first(where: { $0.isCurrent == true })
                    guard let cdi, let aid = cdi.identifier, let page = cdi.page, let t = page.title,
                          let pid = page.projectID, let proj = WMFProject(id: pid),
                          let siteURL = proj.siteURL, let aurl = siteURL.wmfURL(withTitle: t, languageVariantCode: nil) else {
                        throw CustomError.missingTabItem
                    }
                    let tab = WMFArticleTab(identifier: tid, timestamp: tts, isCurrent: cdt.isCurrent,
                                           articles: [WMFArticle(identifier: aid, title: t, project: proj, articleURL: aurl)])
                    try self.userDefaultsStore?.save(key: WMFUserDefaultsKey.articleTabRestoration.rawValue, value: tab)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    public func loadCurrentStateForRestoration() throws -> WMFArticleTab? {
        try userDefaultsStore?.load(key: WMFUserDefaultsKey.articleTabRestoration.rawValue)
    }
    
    public func clearCurrentStateForRestoration() throws {
        try userDefaultsStore?.remove(key: WMFUserDefaultsKey.articleTabRestoration.rawValue)
    }
}

private extension WMFProject {
    var qualifiesForExperiment: Bool {
        switch self {
        case .wikipedia(let language): return ["en", "ar", "de"].contains(language.languageCode.lowercased())
        default: return false
        }
    }
}

private extension Locale {
    var qualifiesForExperiment: Bool {
        guard let id = region?.identifier.lowercased() else { return false }
        let eseap = ["au", "hk", "id", "jp", "my", "mm", "nz", "ph", "sg", "kr", "tw", "th", "vn"]
        let mena = ["dz", "bh", "eg", "jo", "kw", "lb", "ly", "ma", "om", "qa", "sa", "tn", "ae", "ye"]
        return eseap.contains(id) || mena.contains(id) || id == "de"
    }
}

// Sync Bridge Methods

extension WMFArticleTabsDataController {
    
    nonisolated public var shouldShowMoreDynamicTabsV2SyncBridge: Bool {
        var result = false
        let semaphore = DispatchSemaphore(value: 0)
        
        Task {
            result = await self.shouldShowMoreDynamicTabsV2
            semaphore.signal()
        }
        
        semaphore.wait()
        return result
    }
    
    nonisolated public var userHasHiddenArticleSuggestionsTabsSyncBridge: Bool {
        var result = false
        let semaphore = DispatchSemaphore(value: 0)
        
        Task {
            result = await self.userHasHiddenArticleSuggestionsTabs
            semaphore.signal()
        }
        
        semaphore.wait()
        return result
    }
    
    nonisolated public var hasPresentedTooltipsSyncBridge: Bool {
        var result = false
        let semaphore = DispatchSemaphore(value: 0)
        
        Task {
            result = await self.hasPresentedTooltips
            semaphore.signal()
        }
        
        semaphore.wait()
        return result
    }
    
    nonisolated public func loadCurrentStateForRestorationSyncBridge() -> WMFArticleTab? {
        var result: WMFArticleTab? = nil
        let semaphore = DispatchSemaphore(value: 0)
        
        Task {
            do {
                result = try await self.loadCurrentStateForRestoration()
            } catch {
                result = nil
            }
            semaphore.signal()
        }
        
        semaphore.wait()
        return result
    }
}

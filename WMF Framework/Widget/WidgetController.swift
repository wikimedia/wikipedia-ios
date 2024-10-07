import Foundation
import WidgetKit
import CocoaLumberjackSwift

@objc(WMFWidgetController)
public final class WidgetController: NSObject {

    // MARK: Nested Types

    public enum SupportedWidget: String {
        case featuredArticle = "org.wikimedia.wikipedia.widgets.featuredArticle"
        case onThisDay = "org.wikimedia.wikipedia.widgets.onThisDay"
        case pictureOfTheDay = "org.wikimedia.wikipedia.widgets.potd"
        case topRead = "org.wikimedia.wikipedia.widgets.topRead"

        public var identifier: String {
            return self.rawValue
        }
    }

    // MARK: Properties

	@objc public static let shared = WidgetController()
    private let sharedCache = SharedContainerCache(fileName: SharedContainerCacheCommonNames.widgetCache)
    
    private var widgetCache: WidgetCache {
        return sharedCache.loadCache() ?? WidgetCache(settings: .default, featuredContent: nil)
    }

    // MARK: Public

	@objc public func reloadAllWidgetsIfNecessary() {
        guard !Bundle.main.isAppExtension else {
            return
        }

        let dataStore = MWKDataStore.shared()
        let appLanguage = dataStore.languageLinkController.appLanguage
        if let siteURL = appLanguage?.siteURL, let languageCode = appLanguage?.languageCode {
            let updatedWidgetSettings = WidgetSettings(siteURL: siteURL, languageCode: languageCode, languageVariantCode: appLanguage?.languageVariantCode)
            updateCacheWith(settings: updatedWidgetSettings)
        }

        WidgetCenter.shared.reloadAllTimelines()
	}
    
    public func reloadFeaturedArticleWidgetIfNecessary() {
        guard !Bundle.main.isAppExtension else {
            return
        }

        let dataStore = MWKDataStore.shared()
        let appLanguage = dataStore.languageLinkController.appLanguage
        if let siteURL = appLanguage?.siteURL, let languageCode = appLanguage?.languageCode {
            let updatedWidgetSettings = WidgetSettings(siteURL: siteURL, languageCode: languageCode, languageVariantCode: appLanguage?.languageVariantCode)
            updateCacheWith(settings: updatedWidgetSettings)
        }
        
        WidgetCenter.shared.reloadTimelines(ofKind: SupportedWidget.featuredArticle.rawValue)
    }
    
    /// For requesting background time from widgets
    /// - Parameter userCompletion: the completion block to call with the result
    /// - Parameter task: block that takes the `MWKDataStore` to use for updates and the completion block to call when done as parameters
    public func startWidgetUpdateTask<T>(_ userCompletion: @escaping (T) -> Void, _ task: @escaping (MWKDataStore, @escaping (T) -> Void) -> Void) {
        getRetainedSharedDataStore { dataStore in
            task(dataStore, { result in
                DispatchQueue.main.async {
                    self.releaseSharedDataStore {
                        userCompletion(result)
                    }
                }
            })
        }
    }
    
    public func fetchNewestWidgetContentGroup(with kind: WMFContentGroupKind, in dataStore: MWKDataStore, isNetworkFetchAllowed: Bool, isAnyLanguageAllowed: Bool = false, completion:  @escaping (WMFContentGroup?) -> Void) {
        fetchCachedWidgetContentGroup(with: kind, isAnyLanguageAllowed: isAnyLanguageAllowed, in: dataStore) { (contentGroup) in
            guard let todaysContentGroup = contentGroup, todaysContentGroup.isForToday else {
                guard isNetworkFetchAllowed else {
                    completion(contentGroup)
                    return
                }
                self.updateFeedContent(in: dataStore) {
                    // if there's no cached content group after update, return nil
                    self.fetchCachedWidgetContentGroup(with: kind, isAnyLanguageAllowed: isAnyLanguageAllowed, in: dataStore, completion: completion)
                }
                return
            }
            completion(todaysContentGroup)
        }
    }
    
    private func fetchCachedWidgetContentGroup(with kind: WMFContentGroupKind, isAnyLanguageAllowed: Bool, in dataStore: MWKDataStore, completion:  @escaping (WMFContentGroup?) -> Void) {
        assert(Thread.isMainThread, "Cached widget content group must be fetched from the main queue")
        let moc = dataStore.viewContext
        let siteURL = isAnyLanguageAllowed ? dataStore.primarySiteURL : nil
        completion(moc.newestGroup(of: kind, forSiteURL: siteURL))
    }
    
    public func updateFeedContent(in dataStore: MWKDataStore, completion: @escaping () -> Void) {
        dataStore.feedContentController.performDeduplicatedFetch(completion)
    }
    
    private var dataStoreRetainCount: Int = 0
    private var _dataStore: MWKDataStore?
    private var completions: [(MWKDataStore) -> Void] = []
    private var isCreatingDataStore: Bool = false
    private var backgroundActivity: NSObjectProtocol?
    
    /// Returns a `MWKDataStore`for use with widget updates.
    /// Manages a shared instance and a reference count for use by multiple widgets.
    /// Call `releaseSharedDataStore()` when finished with the data store.
    private func getRetainedSharedDataStore(completion: @escaping (MWKDataStore) -> Void) {
        assert(Thread.isMainThread, "Data store must be obtained from the main queue")
        dataStoreRetainCount += 1
        if let dataStore = _dataStore {
            completion(dataStore)
            return
        }
        completions.append(completion)
        guard !isCreatingDataStore else {
            return
        }
        isCreatingDataStore = true
        backgroundActivity = ProcessInfo.processInfo.beginActivity(options: [.background, .suddenTerminationDisabled, .automaticTerminationDisabled], reason: "Wikipedia Extension - " + UUID().uuidString)
        let dataStore = MWKDataStore()
        dataStore.finishSetup {
            dataStore.performLibraryUpdates {
                DispatchQueue.main.async {
                    self._dataStore = dataStore
                    self.isCreatingDataStore = false
                    self.completions.forEach { $0(dataStore) }
                    self.completions.removeAll()
                }
            }
        }
    }
    
    /// Releases the shared `MWKDataStore` returned by `getRetainedSharedDataStore()`.
    private func releaseSharedDataStore(completion: @escaping () -> Void) {
        assert(Thread.isMainThread, "Data store must be released from the main queue")
        dataStoreRetainCount -= 1
        guard dataStoreRetainCount <= 0 else {
            completion()
            return
        }
        dataStoreRetainCount = 0
        let asyncBackgroundActivity = backgroundActivity
        defer {
            backgroundActivity = nil
        }
        let finishBackgroundActivity = {
            if let asyncBackgroundActivity = asyncBackgroundActivity {
                ProcessInfo.processInfo.endActivity(asyncBackgroundActivity)
            }
        }
        guard let dataStoreToTeardown = _dataStore else {
            completion()
            finishBackgroundActivity()
            return
        }
        _dataStore = nil
        dataStoreToTeardown.teardown {
            completion()
            finishBackgroundActivity()
            #if DEBUG
            guard !self.isCreatingDataStore, self._dataStore == nil else { // Don't check open files if another MWKDataStore was created after this one was destroyed
                return
            }
            let openFiles = self.openFilePaths()
            let openSqliteFile = openFiles.first(where: { $0.hasSuffix(".sqlite") })
            assert(openSqliteFile == nil, "There should be no open sqlite files (which in our case are Core Data persistent stores) in the shared app container after the data store is released. The widget still has a lock on these files: \(openFiles)")
            #endif
        }
    }
    
    #if DEBUG
    /// From https://developer.apple.com/forums/thread/655225?page=2
    func openFilePaths() -> [String] {
        (0..<getdtablesize()).compactMap { fd in
            // Return nil for invalid file descriptors.
            var flags: CInt = 0
            guard fcntl(fd, F_GETFL, &flags) >= 0 else {
                return nil
            }
            // Return "?" for file descriptors not associated with a path, for
            // example, a socket.
            var path = [CChar](repeating: 0, count: Int(MAXPATHLEN))
            guard fcntl(fd, F_GETPATH, &path) >= 0 else {
                return "?"
            }
            return String(cString: path)
        }
    }
    #endif
    
}

/// When the old widget data loading model is removed, this should be moved out of this extension into the class itself and refactored (e.g. the properties here don't need to be computed).
public extension WidgetController {

    // MARK: - Computed Properties

    var featuredContentSiteURL: URL {
        return widgetCache.settings.siteURL
    }

    var potdTargetImageSize: CGSize {
        CGSize(width: 1000, height: 1000)
    }

    // MARK: - Utility

    /// This is currently unused. It will be useful when we update the main app to also update the widget's cache when it performs any updates to the featured content in the explore feed.
    func updateCacheWith(featuredContent: WidgetFeaturedContent) {
        var updatedCache = widgetCache
        updatedCache.featuredContent = featuredContent
        sharedCache.saveCache(updatedCache)
    }

    func updateCacheWith(settings: WidgetSettings) {
        var updatedCache = widgetCache
        updatedCache.settings = settings
        sharedCache.saveCache(updatedCache)
    }

    /// Returns cached content if it's available for the current date in the current app selected language
    private func cachedContentIfAvailable() -> WidgetFeaturedContent? {
        let widgetCache = widgetCache
        if let cachedContent = widgetCache.featuredContent, let fetchDate = cachedContent.fetchDate, Calendar.current.isDateInToday(fetchDate), let cachedLanguageCode = cachedContent.featuredArticle?.languageCode, cachedLanguageCode == widgetCache.settings.languageCode, widgetCache.settings.languageVariantCode == cachedContent.fetchedLanguageVariantCode {
            return cachedContent
        }

        return nil
    }

    // MARK: - Fetch Featured Content

    private func fetchFeaturedContent(useCacheIfAvailable: Bool = true, completion: @escaping (WidgetContentFetcher.FeaturedContentResult) -> Void) {
        func performCompletion(result: WidgetContentFetcher.FeaturedContentResult) {
            DispatchQueue.main.async {
                completion(result)
            }
        }

        let fetcher = WidgetContentFetcher.shared
        var widgetCache = widgetCache

        if useCacheIfAvailable, let cachedContent = cachedContentIfAvailable() {
            performCompletion(result: .success(cachedContent))
            return
        }

        // Fetch fresh featured content from network
        fetcher.fetchFeaturedContent(forDate: Date(), siteURL: widgetCache.settings.siteURL, languageCode: widgetCache.settings.languageCode, languageVariantCode: widgetCache.settings.languageVariantCode) { result in
            switch result {
            case .success(let featuredContent):
                widgetCache.featuredContent = featuredContent
                self.sharedCache.saveCache(widgetCache)
                performCompletion(result: .success(featuredContent))
            case .failure(let error):
                self.sharedCache.saveCache(widgetCache)
                performCompletion(result: .failure(error))
            }
        }
    }

    // MARK: - Fetch Top Read Widget Content

    func fetchTopReadContent(isSnapshot: Bool = false, completion: @escaping (WidgetContentFetcher.TopReadResult) -> Void) {
        func performCompletion(result: WidgetContentFetcher.TopReadResult) {
            DispatchQueue.main.async {
                completion(result)
            }
        }

        let fetcher = WidgetContentFetcher.shared
        var widgetCache = widgetCache

        guard !isSnapshot else {
            let previewSnapshot = widgetCache.featuredContent ?? WidgetFeaturedContent.previewContent() ?? WidgetFeaturedContent()
            if let previewTopRead = previewSnapshot.topRead {
                performCompletion(result: .success(previewTopRead))
            } else {
                performCompletion(result: .failure(.contentFailure))
            }
            return
        }

        fetchFeaturedContent { result in
            switch result {
            case .success(var featuredContent):
                if var topRead = featuredContent.topRead {
                    // Fetch images, if available, for the top four elements
                    let group = DispatchGroup()
                    for (index, element) in topRead.topFourElements.enumerated() {
                        group.enter()
                        guard let thumbnailImageSource = element.thumbnailImageSource else {
                            group.leave()
                            continue
                        }

                        fetcher.fetchImageDataFrom(imageSource: thumbnailImageSource) { result in
                            switch result {
                            case .success(let imageData):
                                topRead.elements[index].thumbnailImageSource?.data = imageData
                                group.leave()
                            case .failure:
                                group.leave()
                            }
                        }
                    }

                    group.notify(queue: .main) {
                        featuredContent.topRead = topRead
                        widgetCache.featuredContent = featuredContent
                        self.sharedCache.saveCache(widgetCache)
                        if let featuredTopReadContent = featuredContent.topRead {
                            performCompletion(result: .success(featuredTopReadContent))
                        } else {
                            performCompletion(result: .failure(.contentFailure))
                        }
                    }
                } else {
                    performCompletion(result: .failure(.contentFailure))
                }
            case .failure(let error):
                performCompletion(result: .failure(error))
            }
        }
    }

    // MARK: - Fetch Featured Article Widget Content

    func fetchFeaturedArticleContent(isSnapshot: Bool = false, completion: @escaping (WidgetContentFetcher.FeaturedArticleResult) -> Void) {
        func performCompletion(result: WidgetContentFetcher.FeaturedArticleResult) {
            DispatchQueue.main.async {
                completion(result)
            }
        }

        let fetcher = WidgetContentFetcher.shared
        var widgetCache = widgetCache

        guard !isSnapshot else {
            let previewSnapshot = widgetCache.featuredContent ?? WidgetFeaturedContent.previewContent() ?? WidgetFeaturedContent()
            if let previewArticle = previewSnapshot.featuredArticle {
                performCompletion(result: .success(previewArticle))
            } else {
                performCompletion(result: .failure(.contentFailure))
            }
            return
        }

        guard WidgetFeaturedArticle.supportedLanguageCodes.contains(widgetCache.settings.languageCode) else {
            performCompletion(result: .failure(.unsupportedLanguage))
            return
        }

        fetchFeaturedContent { result in
            switch result {
            case .success(var featuredContent):
                if let featuredArticleThumbnailImageSource = featuredContent.featuredArticle?.thumbnailImageSource {
                    fetcher.fetchImageDataFrom(imageSource: featuredArticleThumbnailImageSource) { imageResult in
                        featuredContent.featuredArticle?.thumbnailImageSource?.data = try? imageResult.get()
                        widgetCache.featuredContent = featuredContent
                        self.sharedCache.saveCache(widgetCache)
                        if let featureArticle = featuredContent.featuredArticle {
                            performCompletion(result: .success(featureArticle))
                        } else {
                            performCompletion(result: .failure(.contentFailure))
                        }
                    }
                } else {
                    widgetCache.featuredContent = featuredContent
                    self.sharedCache.saveCache(widgetCache)
                    if let featureArticle = featuredContent.featuredArticle {
                        performCompletion(result: .success(featureArticle))
                    } else {
                        performCompletion(result: .failure(.contentFailure))
                    }
                }
            case .failure(let error):
                performCompletion(result: .failure(error))
            }
        }
    }

    // MARK: - Fetch Picture of the Day Widget Content

    func fetchPictureOfTheDayContent(isSnapshot: Bool = false, completion: @escaping (WidgetContentFetcher.PictureOfTheDayResult) -> Void) {
        func performCompletion(result: WidgetContentFetcher.PictureOfTheDayResult) {
            DispatchQueue.main.async {
                completion(result)
            }
        }

        let fetcher = WidgetContentFetcher.shared
        var widgetCache = widgetCache

        guard !isSnapshot else {
            let previewSnapshot = widgetCache.featuredContent ?? WidgetFeaturedContent.previewContent() ?? WidgetFeaturedContent()
            if let previewPictureOfTheDay = previewSnapshot.pictureOfTheDay {
                performCompletion(result: .success(previewPictureOfTheDay))
            } else {
                performCompletion(result: .failure(.contentFailure))
            }
            return
        }

        fetchFeaturedContent { result in
            switch result {
            case .success(var featuredContent):
                if var imageSource = featuredContent.pictureOfTheDay?.originalImageSource {
                    imageSource.source = WMFChangeImageSourceURLSizePrefix(imageSource.source, Int(self.potdTargetImageSize.width))
                    featuredContent.pictureOfTheDay?.originalImageSource = imageSource
                    fetcher.fetchImageDataFrom(imageSource: imageSource) { imageResult in
                        featuredContent.pictureOfTheDay?.originalImageSource?.data = try? imageResult.get()
                        widgetCache.featuredContent = featuredContent
                        self.sharedCache.saveCache(widgetCache)

                        if let pictureOftheDay = featuredContent.pictureOfTheDay {
                            performCompletion(result: .success(pictureOftheDay))
                        } else {
                            performCompletion(result: .failure(.contentFailure))
                        }
                    }
                } else {
                    widgetCache.featuredContent = featuredContent
                    self.sharedCache.saveCache(widgetCache)
                    performCompletion(result: .failure(.contentFailure))
                }
            case .failure(let error):
                performCompletion(result: .failure(error))
            }
        }
    }

}

@import Foundation;
#import <WMF/WMFBlockDefinitions.h>

@class MWKSavedPageList;
@class MWKRecentSearchList;
@class WMFArticle;
@class WMFExploreFeedContentController;
@class WMFReadingListsController;
@class WikidataDescriptionEditingController;
@class RemoteNotificationsController;
@class WMFArticleSummaryController;
@class MobileviewToMobileHTMLConverter;
@class MWKLanguageLinkController;
@class WMFSession;
@class WMFConfiguration;
@class WMFPermanentCacheController;
@class WMFNotificationsController;
@class WMFAuthenticationManager;
@class WMFABTestsController;

@protocol ABTestsPersisting;

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const MWKDataStoreValidImageSitePrefix;

/**
 * Creates an image URL by appending @c path to @c MWKDataStoreValidImageSitePrefix.
 * @param path The relative path to an image <b>without the leading slash</b>. For example,
 *             <code>@"File.jpg/440px-File.jpg"</code>.
 */
extern NSString *MWKCreateImageURLWithPath(NSString *path);

/**
 * Subscribe to get notifications when a WMFArticle is
 * added to saved pages, history, etc…
 */
extern NSString *const WMFArticleUpdatedNotification;
extern NSString *const WMFArticleDeletedNotification;
extern NSString *const WMFArticleDeletedNotificationUserInfoArticleKeyKey; // User info key for the article key
extern NSString *const WMFBackgroundContextDidSave;
extern NSString *const WMFFeedImportContextDidSave;
extern NSString *const WMFViewContextDidSave;

typedef NS_OPTIONS(NSUInteger, RemoteConfigOption) {
    RemoteConfigOptionReadingLists = 1 << 0,
    RemoteConfigOptionGeneric = 1 << 1
};

@interface MWKDataStore : NSObject

/**
 *  Initialize with sharedInstance database and legacyDataBasePath
 *
 *  @return A data store
 */
- (instancetype)init;

- (instancetype)initWithContainerURL:(NSURL *)containerURL NS_DESIGNATED_INITIALIZER;

/// Call to cancel any async tasks and wait for completion
- (void)teardown:(nullable dispatch_block_t)completion;

@property (readonly, strong, nonatomic) NSURL *containerURL;
@property (readonly, strong, nonatomic) WMFSession *session;
@property (readonly, strong, nonatomic) WMFConfiguration *configuration;
@property (readonly, strong, nonatomic) WMFPermanentCacheController *cacheController;

- (void)performLibraryUpdates:(dispatch_block_t)completion needsMigrateBlock:(dispatch_block_t)needsMigrateBlock;
- (void)performInitialLibrarySetup;
#if TEST
- (void)performTestLibrarySetup;
#endif

- (void)updateLocalConfigurationFromRemoteConfigurationWithCompletion:(nullable void (^)(NSError *nullable))completion;
@property (readwrite, nonatomic) BOOL isLocalConfigUpdateAllowed;
@property (readonly, nonatomic) RemoteConfigOption remoteConfigsThatFailedUpdate;

@property (readonly, strong, nonatomic) WMFAuthenticationManager *authenticationManager;
@property (readonly, strong, nonatomic) MWKSavedPageList *savedPageList;
@property (readonly, strong, nonatomic) MWKRecentSearchList *recentSearchList;
@property (readonly, strong, nonatomic) WMFReadingListsController *readingListsController;
@property (readonly, strong, nonatomic) WikidataDescriptionEditingController *wikidataDescriptionEditingController;
@property (readonly, strong, nonatomic) RemoteNotificationsController *remoteNotificationsController;
@property (readonly, strong, nonatomic) WMFArticleSummaryController *articleSummaryController;
@property (readonly, strong, nonatomic) MWKLanguageLinkController *languageLinkController;
@property (readonly, strong, nonatomic) WMFNotificationsController *notificationsController;

@property (nonatomic, strong, readonly) NSManagedObjectContext *viewContext;
@property (nonatomic, strong, readonly) NSManagedObjectContext *feedImportContext;

/**
 * Returns the siteURL of the user's first preferred language.
 */
@property (readonly, copy, nonatomic, nullable) NSURL *primarySiteURL;

#pragma mark - Caching

@property (readonly, strong, nonatomic) MobileviewToMobileHTMLConverter *mobileviewConverter;

- (void)performBackgroundCoreDataOperationOnATemporaryContext:(nonnull void (^)(NSManagedObjectContext *moc))mocBlock;

@property (nonatomic, strong, readonly) WMFExploreFeedContentController *feedContentController;

- (void)teardownFeedImportContext;

- (void)prefetchArticles; // fill the article cache to speed up initial feed load

- (nullable WMFArticle *)fetchArticleWithURL:(NSURL *)URL inManagedObjectContext:(NSManagedObjectContext *)moc;
- (nullable WMFArticle *)fetchOrCreateArticleWithURL:(NSURL *)URL inManagedObjectContext:(NSManagedObjectContext *)moc;
- (nullable WMFArticle *)fetchArticleWithKey:(NSString *)key variant:(nullable NSString *)variant inManagedObjectContext:(NSManagedObjectContext *)moc;

- (nullable WMFArticle *)fetchArticleWithURL:(NSURL *)URL;         //uses the view context
- (nullable WMFArticle *)fetchOrCreateArticleWithURL:(NSURL *)URL; //uses the view context
- (nullable WMFArticle *)fetchArticleWithKey:(NSString *)key variant:(nullable NSString *)variant; //uses the view context
- (nullable WMFArticle *)fetchArticleWithKey:(NSString *)key; // Temporary shim for areas like reading lists that are not yet variant-aware

- (nullable WMFArticle *)fetchArticleWithWikidataID:(NSString *)wikidataID; //uses the view context

- (BOOL)save:(NSError **)error;

- (void)clearMemoryCache;

/// Clears both the memory cache and the URLSession cache
- (void)clearTemporaryCache;

#pragma mark - Legacy Datastore methods

@property (readonly, copy, nonatomic) NSString *basePath;

/// Deprecated: Use dependency injection
+ (MWKDataStore *)shared;

/// Deprecated: Used only for mobile-html conversion
- (NSString *)pathForArticleURL:(NSURL *)url;

- (BOOL)saveRecentSearchList:(MWKRecentSearchList *)list error:(NSError **)error;

- (NSArray *)recentSearchListData;

// Storage helper methods

- (NSError *)removeFolderAtBasePath;

#pragma mark - ABTestsController

@property (readonly, strong, nonatomic) WMFABTestsController *abTestsController;

- (void)setupAbTestsControllerWithPersistenceService: (id<ABTestsPersisting>)persistenceService;

@end

NS_ASSUME_NONNULL_END

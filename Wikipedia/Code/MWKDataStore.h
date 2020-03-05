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

@property (readonly, strong, nonatomic) NSURL *containerURL;

- (void)performLibraryUpdates:(dispatch_block_t)completion;
- (void)performUpdatesFromLibraryVersion:(NSUInteger)currentLibraryVersion inManagedObjectContext:(NSManagedObjectContext *)moc;

- (void)updateLocalConfigurationFromRemoteConfigurationWithCompletion:(nullable void (^)(NSError *nullable))completion;
@property (readwrite, nonatomic) BOOL isLocalConfigUpdateAllowed;
@property (readonly, nonatomic) RemoteConfigOption remoteConfigsThatFailedUpdate;

@property (readonly, strong, nonatomic) MWKSavedPageList *savedPageList;
@property (readonly, strong, nonatomic) MWKRecentSearchList *recentSearchList;
@property (readonly, strong, nonatomic) WMFReadingListsController *readingListsController;
@property (readonly, strong, nonatomic) WikidataDescriptionEditingController *wikidataDescriptionEditingController;
@property (readonly, strong, nonatomic) RemoteNotificationsController *remoteNotificationsController;
@property (readonly, strong, nonatomic) WMFArticleSummaryController *articleSummaryController;

@property (nonatomic, strong, readonly) NSManagedObjectContext *viewContext;
@property (nonatomic, strong, readonly) NSManagedObjectContext *feedImportContext;

#pragma mark - Caching

@property (readonly, strong, nonatomic) MobileviewToMobileHTMLConverter *mobileviewConverter;

- (void)performBackgroundCoreDataOperationOnATemporaryContext:(nonnull void (^)(NSManagedObjectContext *moc))mocBlock;

@property (nonatomic, strong, readonly) WMFExploreFeedContentController *feedContentController;

- (void)teardownFeedImportContext;

- (void)prefetchArticles; // fill the article cache to speed up initial feed load

- (nullable WMFArticle *)fetchArticleWithURL:(NSURL *)URL inManagedObjectContext:(NSManagedObjectContext *)moc;
- (nullable WMFArticle *)fetchArticleWithKey:(NSString *)key inManagedObjectContext:(NSManagedObjectContext *)moc;
- (nullable WMFArticle *)fetchOrCreateArticleWithURL:(NSURL *)URL inManagedObjectContext:(NSManagedObjectContext *)moc;

- (nullable WMFArticle *)fetchArticleWithURL:(NSURL *)URL;         //uses the view context
- (nullable WMFArticle *)fetchArticleWithKey:(NSString *)key;      //uses the view context
- (nullable WMFArticle *)fetchOrCreateArticleWithURL:(NSURL *)URL; //uses the view context

- (nullable WMFArticle *)fetchArticleWithWikidataID:(NSString *)wikidataID; //uses the view context

- (BOOL)isArticleWithURLExcludedFromFeed:(NSURL *)articleURL inManagedObjectContext:(NSManagedObjectContext *)moc;
- (void)setIsExcludedFromFeed:(BOOL)isExcludedFromFeed withArticleURL:(NSURL *)articleURL inManagedObjectContext:(NSManagedObjectContext *)moc;

- (void)setIsExcludedFromFeed:(BOOL)isExcludedFromFeed withArticleURL:(NSURL *)articleURL;
- (BOOL)isArticleWithURLExcludedFromFeed:(NSURL *)articleURL;

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

@end

NS_ASSUME_NONNULL_END

@class MWKArticle;
@class MWKSection;
@class MWKImage;
@class MWKHistoryEntry;
@class MWKHistoryList;
@class MWKSavedPageList;
@class MWKRecentSearchList;
@class MWKImageInfo;
@class MWKImageList;
@class WMFArticle;

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const MWKDataStoreValidImageSitePrefix;

/**
 * Creates an image URL by appending @c path to @c MWKDataStoreValidImageSitePrefix.
 * @param path The relative path to an image <b>without the leading slash</b>. For example,
 *             <code>@"File.jpg/440px-File.jpg"</code>.
 */
extern NSString *MWKCreateImageURLWithPath(NSString *path);

/**
 * Subscribe to get notifications when an article is saved to the store
 * The article saved is in the userInfo under the `MWKArticleKey`
 * Notificaton is dispatched on the main thread
 */
extern NSString *const MWKArticleSavedNotification;
extern NSString *const MWKArticleKey;

extern NSString *const MWKSetupDataSourcesNotification;
extern NSString *const MWKTeardownDataSourcesNotification;

/**
 * Subscribe to get notifications when an item is
 * added to saved pages, history, etc…
 * The url of the item updated will be in the
 * MWKURLKey of the userInfo
 */
extern NSString *const MWKItemUpdatedNotification;
extern NSString *const MWKURLKey;
extern NSString *const MWKSavedDateKey;

@interface MWKDataStore : NSObject

/**
 *  Initialize with sharedInstance database and legacyDataBasePath
 *
 *  @return A data store
 */
- (instancetype)init;

- (instancetype)initWithContainerURL:(NSURL *)containerURL NS_DESIGNATED_INITIALIZER;

+ (BOOL)migrateToSharedContainer:(NSError **)error;
- (BOOL)migrateToCoreData:(NSError **)error;
- (void)migrateToQuadKeyLocationIfNecessaryWithCompletion:(nonnull void (^)(NSError *))completion;

@property (readonly, strong, nonatomic) MWKHistoryList *historyList;
@property (readonly, strong, nonatomic) MWKSavedPageList *savedPageList;
@property (readonly, strong, nonatomic) MWKRecentSearchList *recentSearchList;

@property (nonatomic, strong, readonly) NSManagedObjectContext *viewContext;

- (nullable WMFArticle *)fetchArticleForURL:(NSURL *)URL;
- (nullable WMFArticle *)fetchArticleForKey:(NSString *)key;
- (nullable WMFArticle *)fetchOrCreateArticleForURL:(NSURL *)URL;

- (BOOL)isArticleWithURLExcludedFromFeed:(NSURL *)articleURL;
- (void)setIsExcludedFromFeed:(BOOL)isExcludedFromFeed forArticleURL:(NSURL *)articleURL;

- (BOOL)save:(NSError **)error;

- (void)enumerateArticlesWithBlock:(void (^)(WMFArticle *_Nonnull entry, BOOL *stop))block;

#pragma mark - Legacy Datastore methods

/**
 *  Save the @c article asynchronously. If an existing save operation exists for this article or an article with the same URL, it will be cancelled and re-added with this copy of the article.
 *
 *  @param article    The article to save.
 **/
- (void)asynchronouslyCacheArticle:(MWKArticle *)article;

- (void)asynchronouslyCacheArticle:(MWKArticle *)article completion:(nullable dispatch_block_t)completion;

/**
 *  Cancel the asynchronous save for the @c article.
 *
 *  @param article    The article to cancel.
 **/
- (void)cancelAsynchronousCacheForArticle:(MWKArticle *)article;

@property (readonly, copy, nonatomic) NSString *basePath;

/**
 *  Path for the default main data store.
 *  Use this to intitialize a data store with the default path
 *
 *  @return The path
 */
+ (NSString *)mainDataStorePath;
+ (NSString *)appSpecificMainDataStorePath; // deprecated, use mainDataStorePath

// Path methods
- (NSString *)joinWithBasePath:(NSString *)path;
- (NSString *)pathForSites; // Excluded from iCloud Backup. Includes every site, article, title.
- (NSString *)pathForDomainInURL:(NSURL *)url;
- (NSString *)pathForArticlesInDomainFromURL:(NSURL *)url;
- (NSString *)pathForArticleURL:(NSURL *)url;

/**
 * Path to the directory which contains data for the specified article.
 * @see -pathForArticleURL:
 */
- (NSString *)pathForArticle:(MWKArticle *)article;
- (NSString *)pathForSectionsInArticleWithURL:(NSURL *)url;
- (NSString *)pathForSectionId:(NSUInteger)sectionId inArticleWithURL:(NSURL *)url;
- (NSString *)pathForSection:(MWKSection *)section;
- (NSString *)pathForImagesWithArticleURL:(NSURL *)url;
- (NSString *)pathForImageURL:(NSString *)imageURL forArticleURL:(NSURL *)articleURL;

- (NSString *)pathForImage:(MWKImage *)image;

/**
 * The path where the image info is stored for a given article.
 * @param url The @c NSURL for the MWKArticle which contains the desired image info.
 * @return The path to the <b>.plist</b> file where image info for an article would be stored.
 */
- (NSString *)pathForImageInfoForArticleWithURL:(NSURL *)url;

// Raw save methods

/**
 *  Saves the article to the store
 *  This is a non-op if the article is a main page
 *
 *  @param article the article to save
 */
- (void)saveArticle:(MWKArticle *)article;

/**
 *  Saves the section to the store
 *  This is a non-op if the section.article is a main page
 *
 *  @param section the section to save
 */
- (void)saveSection:(MWKSection *)section;

/**
 *  Saves the section to the store
 *  This is a non-op if the section.article is a main page
 *
 *  @param html    The text to save
 *  @param section the section to save
 */
- (void)saveSectionText:(NSString *)html section:(MWKSection *)section;

/**
 *  Saves the image to the store
 *  This is a non-op if the image.article is a main page
 *
 *  @param image The image to save
 */
- (void)saveImage:(MWKImage *)image;

- (BOOL)saveRecentSearchList:(MWKRecentSearchList *)list error:(NSError **)error;

- (void)deleteArticle:(MWKArticle *)article;

/**
 * Save an array of image info objects which belong to the specified article.
 * @param imageInfo An array of @c MWKImageInfo objects belonging to the specified article.
 * @param url   The url for the article which contains the specified images.
 * @discussion Image info objects are stored under an article so they can be easily referenced and removed alongside
 *             the article.
 */
- (void)saveImageInfo:(NSArray *)imageInfo forArticleURL:(NSURL *)url;

///
/// @name Article Load Methods
///

/**
 *  Retrieves an existing article from the receiver.
 *
 *  This will check memory cache first, falling back to disk if necessary. If data is read from disk, it is inserted
 *  into the memory cache before returning, allowing subsequent calls to this method to hit the memory cache.
 *
 *  @param url The url under which article data was previously stored.
 *
 *  @return An article, or @c nil if none was found.
 */
- (nullable MWKArticle *)existingArticleWithURL:(NSURL *)url;

/**
 *  Attempt to create an article object from data on disk.
 *
 *  @param url The url under which article data was previously stored.
 *
 *  @return An article, or @c nil if none was found.
 */
- (nullable MWKArticle *)articleFromDiskWithURL:(NSURL *)url;

/**
 *  Get or create an article with a given title.
 *
 *  If an article already exists for this title return it. Otherwise, create a new object and return it without saving
 *  it.
 *
 *  @param url The url related to the article data.
 *
 *  @return An article object with the given title.
 *
 *  @see -existingArticleWithURL:
 */
- (MWKArticle *)articleWithURL:(NSURL *)url;

- (MWKSection *)sectionWithId:(NSUInteger)sectionId article:(MWKArticle *)article;
- (NSString *)sectionTextWithId:(NSUInteger)sectionId article:(MWKArticle *)article;
- (nullable MWKImage *)imageWithURL:(NSString *)url article:(MWKArticle *)article;
- (NSArray *)imageInfoForArticleWithURL:(NSURL *)url;

- (NSArray *)historyListData;
- (NSDictionary *)savedPageListData;
- (NSArray *)recentSearchListData;

// Storage helper methods

- (NSError *)removeFolderAtBasePath;

- (BOOL)hasHTMLFileForSection:(MWKSection *)section;

- (void)clearMemoryCache;

- (void)removeUnreferencedArticlesFromDiskCacheWithFailure:(WMFErrorHandler)failure success:(WMFSuccessHandler)success;
- (void)removeArticlesWithURLsFromCache:(NSArray<NSURL *> *)titlesToRemove;

- (void)startCacheRemoval;
- (void)stopCacheRemoval;

- (NSArray *)legacyImageURLsForArticle:(MWKArticle *)article;

@end

NS_ASSUME_NONNULL_END

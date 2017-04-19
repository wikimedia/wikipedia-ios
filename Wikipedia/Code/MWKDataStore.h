
#import <Foundation/Foundation.h>

@class MWKSite;
@class MWKTitle;
@class MWKArticle;
@class MWKSection;
@class MWKImage;
@class MWKHistoryList;
@class MWKSavedPageList;
@class MWKRecentSearchList;
@class MWKUserDataStore;
@class MWKImageInfo;
@class MWKImageList;

FOUNDATION_EXPORT NSString* const MWKDataStoreValidImageSitePrefix;

/**
 * Creates an image URL by appending @c path to @c MWKDataStoreValidImageSitePrefix.
 * @param path The relative path to an image <b>without the leading slash</b>. For example,
 *             <code>@"File.jpg/440px-File.jpg"</code>.
 */
extern NSString* MWKCreateImageURLWithPath(NSString* path);

/**
 * Subscribe to get notifications when an article is saved to the store
 * The article saved is in the userInfo under the `MWKArticleKey`
 * Notificaton is dispatched on the main thread
 */
extern NSString* const MWKArticleSavedNotification;
extern NSString* const MWKArticleKey;

@interface MWKDataStore : NSObject

@property (readonly, copy, nonatomic) NSString* basePath;

@property (readonly, strong, nonatomic) MWKUserDataStore* userDataStore;

/**
 *  Path for the default main data store.
 *  Use this to intitialize a data store with the default path
 *
 *  @return The path
 */
+ (NSString*)mainDataStorePath;

- (instancetype)initWithBasePath:(NSString*)basePath;

// Path methods
- (NSString*)joinWithBasePath:(NSString*)path;
- (NSString*)pathForSites; // Excluded from iCloud Backup. Includes every site, article, title.
- (NSString*)pathForSite:(MWKSite*)site;
- (NSString*)pathForArticlesWithSite:(MWKSite*)site;
- (NSString*)pathForTitle:(MWKTitle*)title;

/**
 * Path to the directory which contains data for the specified article.
 * @see -pathForTitle:
 */
- (NSString*)pathForArticle:(MWKArticle*)article;
- (NSString*)pathForSectionsWithTitle:(MWKTitle*)title;
- (NSString*)pathForSectionId:(NSUInteger)sectionId title:(MWKTitle*)title;
- (NSString*)pathForSection:(MWKSection*)section;
- (NSString*)pathForImagesWithTitle:(MWKTitle*)title;
- (NSString*)pathForImageURL:(NSString*)url title:(MWKTitle*)title;
- (NSString*)pathForImage:(MWKImage*)image;
- (NSString*)pathForImageData:(MWKImage*)image;
- (NSString*)pathForImageData:(NSString*)sourceURL title:(MWKTitle*)title;

/**
 * The path where the image info is stored for a given article.
 * @param article The @c MWKArticle which contains the desired image info.
 * @return The path to the <b>.plist</b> file where image info for an article would be stored.
 */
- (NSString*)pathForTitleImageInfo:(MWKTitle*)title;

// Raw save methods

/**
 *  Saves the article to the store
 *  This is a non-op if the article is a main page
 *
 *  @param article the article to save
 */
- (void)saveArticle:(MWKArticle*)article;

/**
 *  Saves the section to the store
 *  This is a non-op if the section.article is a main page
 *
 *  @param section the section to save
 */
- (void)saveSection:(MWKSection*)section;

/**
 *  Saves the section to the store
 *  This is a non-op if the section.article is a main page
 *
 *  @param html    The text to save
 *  @param section the section to save
 */
- (void)saveSectionText:(NSString*)html section:(MWKSection*)section;

/**
 *  Saves the image to the store
 *  This is a non-op if the image.article is a main page
 *
 *  @param image The image to save
 */
- (void)saveImage:(MWKImage*)image;

/**
 *  Saves the image to the store
 *  This is a non-op if the image.article is a main page
 *
 *  @param data  The data to save
 *  @param image The image to save
 */
- (void)saveImageData:(NSData*)data image:(MWKImage*)image;


- (BOOL)saveHistoryList:(MWKHistoryList*)list error:(NSError**)error;
- (BOOL)saveSavedPageList:(MWKSavedPageList*)list error:(NSError**)error;
- (BOOL)saveRecentSearchList:(MWKRecentSearchList*)list error:(NSError**)error;

/**
 *  Saves the image list to the store
 *  This is a non-op if the image.article is a main page
 *
 *  @param imageList The image list to save
 */
- (void)saveImageList:(MWKImageList*)imageList;

- (void)deleteArticle:(MWKArticle*)article;

/**
 * Save an array of image info objects which belong to the specified article.
 * @param imageInfo An array of @c MWKImageInfo objects belonging to the specified article.
 * @param article   The article which contains the specified images.
 * @discussion Image info objects are stored under an article so they can be easily referenced and removed alongside
 *             the article.
 */
- (void)saveImageInfo:(NSArray*)imageInfo forTitle:(MWKTitle*)title;

///
/// @name Article Load Methods
///

/**
 *  Retrieves an existing article from the receiver.
 *
 *  This will check memory cache first, falling back to disk if necessary. If data is read from disk, it is inserted
 *  into the memory cache before returning, allowing subsequent calls to this method to hit the memory cache.
 *
 *  @param title The title under which article data was previously stored.
 *
 *  @return An article, or @c nil if none was found.
 */
- (MWKArticle*)existingArticleWithTitle:(MWKTitle*)title;

/**
 *  Attempt to create an article object from data on disk.
 *
 *  @param title The title under which article data was previously stored.
 *
 *  @return An article, or @c nil if none was found.
 */
- (MWKArticle*)articleFromDiskWithTitle:(MWKTitle*)title;

/**
 *  Get or create an article with a given title.
 *
 *  If an article already exists for this title return it. Otherwise, create a new object and return it without saving
 *  it.
 *
 *  @param title The title related to the article data.
 *
 *  @return An article object with the given title.
 *
 *  @see -existingArticleWithTitle:
 */
- (MWKArticle*)articleWithTitle:(MWKTitle*)title;

- (MWKSection*)sectionWithId:(NSUInteger)sectionId article:(MWKArticle*)article;
- (NSString*)sectionTextWithId:(NSUInteger)sectionId article:(MWKArticle*)article;
- (MWKImage*)imageWithURL:(NSString*)url article:(MWKArticle*)article;
- (NSData*)imageDataWithImage:(MWKImage*)image;
- (NSArray*)imageInfoForTitle:(MWKTitle*)title;


- (NSArray*)     historyListData;
- (NSDictionary*)savedPageListData;
- (NSArray*)     recentSearchListData;



// Storage helper methods

- (MWKImageList*)imageListWithArticle:(MWKArticle*)article section:(MWKSection*)section;

- (void)iterateOverArticles:(void (^)(MWKArticle*))block;

- (NSError*)removeFolderAtBasePath;

- (BOOL)hasHTMLFileForSection:(MWKSection*)section;

- (void)clearMemoryCache;

@end

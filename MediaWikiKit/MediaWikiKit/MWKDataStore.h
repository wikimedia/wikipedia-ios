
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

@interface MWKDataStore : NSObject

@property (readonly) NSString* basePath;

- (instancetype)initWithBasePath:(NSString*)basePath;

// Path methods
- (NSString*)joinWithBasePath:(NSString*)path;
- (NSString*)pathForSites;
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

/**
 * The path where the image info is stored for a given article.
 * @param article The @c MWKArticle which contains the desired image info.
 * @return The path to the <b>.plist</b> file where image info for an article would be stored.
 */
- (NSString*)pathForArticleImageInfo:(MWKArticle*)article;

// Raw save methods
- (void)saveArticle:(MWKArticle*)article;
- (void)saveSection:(MWKSection*)section;
- (void)saveSectionText:(NSString*)html section:(MWKSection*)section;
- (void)saveImage:(MWKImage*)image;
- (void)saveImageData:(NSData*)data image:(MWKImage*)image;
- (BOOL)saveHistoryList:(MWKHistoryList*)list error:(NSError**)error;
- (void)saveSavedPageList:(MWKSavedPageList*)list;
- (void)saveRecentSearchList:(MWKRecentSearchList*)list;
- (void)saveImageList:(MWKImageList*)imageList;

/**
 * Save an array of image info objects which belong to the specified article.
 * @param imageInfo An array of @c MWKImageInfo objects belonging to the specified article.
 * @param article   The article which contains the specified images.
 * @discussion Image info objects are stored under an article so they can be easily referenced and removed alongside
 *             the article.
 */
- (void)saveImageInfo:(NSArray*)imageInfo forArticle:(MWKArticle*)article;

// Raw load methods
- (MWKArticle*)articleWithTitle:(MWKTitle*)title;
- (MWKSection*)sectionWithId:(NSUInteger)sectionId article:(MWKArticle*)article;
- (NSString*)sectionTextWithId:(NSUInteger)sectionId article:(MWKArticle*)article;
- (MWKImage*)imageWithURL:(NSString*)url article:(MWKArticle*)article;
- (NSData*)imageDataWithImage:(MWKImage*)image;
- (MWKHistoryList*)     historyList;
- (MWKSavedPageList*)   savedPageList;
- (MWKRecentSearchList*)recentSearchList;
- (NSArray*)imageInfoForArticle:(MWKArticle*)article;

// Storage helper methods

/// Returns a new `MWKUserDataStore` (i.e. _not_ a lazy property).
- (MWKUserDataStore*)userDataStore;

- (MWKImageList*)imageListWithArticle:(MWKArticle*)article section:(MWKSection*)section;

- (void)iterateOverArticles:(void (^)(MWKArticle*))block;

- (NSError*)removeFolderAtBasePath;

@end

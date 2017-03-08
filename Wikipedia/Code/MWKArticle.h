#import <UIKit/UIKit.h>
@import CoreLocation;

#import "MWKSiteDataObject.h"
NS_ASSUME_NONNULL_BEGIN
static const NSInteger kMWKArticleSectionNone = -1;

@class MWKDataStore;
@class MWKSection;
@class MWKSectionList;
@class MWKImage;
@class MWKImageList;
@class MWKProtectionStatus;

@interface MWKArticle : MWKSiteDataObject

/// Data store used for reading & writing related entities.
@property (readonly, weak, nonatomic, nullable) MWKDataStore *dataStore;

// Metadata
@property (readonly, strong, nonatomic, nullable) NSURL *redirectedURL;    // optional
@property (readonly, strong, nonatomic, nullable) NSDate *lastmodified;    // required
@property (readonly, strong, nonatomic, nullable) MWKUser *lastmodifiedby; // required
@property (readonly, assign, nonatomic) int articleId;                     // required; -> 'id'
@property (readonly, strong, nonatomic, nullable) NSNumber *revisionId;

@property (copy, nonatomic, nullable) NSString *acceptLanguageRequestHeader;

/**
 * Number of links to other wikis on this page.
 *
 * This is *mostly* links to the same topic/entity in another language, but not always. See the comments
 * in LanguageLinksFetcher. Be sure to double check that you add special handling when necessary. For example, main
 * pages can have a misleading non-zero languagecount.
 */
@property (readonly, assign, nonatomic) int languagecount;

@property (readonly, copy, nonatomic, nullable) NSString *displaytitle;            // optional
@property (readonly, strong, nonatomic, nullable) MWKProtectionStatus *protection; // required
@property (readonly, assign, nonatomic) BOOL editable;                             // required
@property (readonly, assign, nonatomic) BOOL hasMultipleLanguages;

/// Whether or not the receiver is the main page for its @c site.
@property (readonly, assign, nonatomic, getter=isMain) BOOL main;

@property (readonly, copy, nonatomic, nullable) NSString *thumbnailURL; // optional; generated from imageURL
@property (readwrite, copy, nonatomic, nullable) NSString *imageURL;    // optional; pulled in article request

- (nullable NSString *)bestThumbnailImageURL;

@property (readonly, copy, nonatomic, nullable) NSString *entityDescription; // optional; currently pulled separately via wikidata
@property (readonly, copy, nonatomic, nullable) NSString *searchSnippet;     //Snippet returned from search results

@property (readonly, strong, nonatomic, nullable) MWKSectionList *sections;

@property (readonly, strong, nonatomic, nullable) MWKImage *thumbnail;
@property (readonly, strong, nonatomic, nullable) MWKImage *image;

@property (readonly, strong, nonatomic, nullable) MWKImage *leadImage;

@property (readonly, strong, nonatomic, nullable) NSString *summary;

@property (readonly, nonatomic) NSInteger ns;

@property (readonly, nonatomic) CLLocationCoordinate2D coordinate;

- (nullable MWKImage *)bestThumbnailImage;

/**
 *  Array of `MWKCitation` objects parsed from the receiver's reference list.
 *
 *  Might be `nil` if the section containing the reference list hasn't been downloaded, be sure to check `isCached`
 *  and fetch the full article contents if necessary.  Might also be `nil` if an error occurred, in which case the
 *  citations should be viewed in the webview.
 */
@property (readonly, strong, nonatomic, nullable) NSArray *citations;

- (instancetype)initWithURL:(NSURL *)url dataStore:(nullable MWKDataStore *)dataStore;
- (instancetype)initWithURL:(NSURL *)url dataStore:(nullable MWKDataStore *)dataStore dict:(NSDictionary *)dict;
- (instancetype)initWithURL:(NSURL *)url dataStore:(nullable MWKDataStore *)dataStore searchResultsDict:(NSDictionary *)dict;

/**
 * Import article and section metadata (and text if available)
 * from an API mobileview JSON response, save it to the database,
 * and make it available through this object.
 */
- (void)importMobileViewJSON:(NSDictionary *)jsonDict;

- (nullable MWKImage *)imageWithURL:(NSString *)url;
- (nullable MWKImage *)existingImageWithURL:(NSString *)url;

/**
 *  Check if the receiver is equal to the given article.
 *
 *  This method is meant to be a good compromise between comprehensive equality checking and speed. For a more detailed
 *  check which takes into account the full content of the article (e.g. section text), use `isDeeplyEqualToArticle:`.
 *
 *  @param article Another `MWKArticle`
 *
 *  @return Whether or not the two articles are equal.
 */
- (BOOL)isEqualToArticle:(MWKArticle *)article;

/**
 *  Check if the receiver is comprehensively equal to another article.
 *
 *  Only use this method when you both 1) need to check the articles' content and 2) can afford to load all the section
 *  text into memory (i.e. ideally not on the main thread, and definitely not in a tight loop).
 *
 *  @param article Another `MWKArticle`.
 *
 *  @return Whether the two articles are equal.
 */
- (BOOL)isDeeplyEqualToArticle:(MWKArticle *)article;

- (void)save;

- (void)remove;

- (BOOL)isCached;

/**
 *  @return The HTML for the article (all of the sections)
 */
- (NSString *)articleHTML;

- (nullable NSArray<NSURL *> *)disambiguationURLs;

- (nullable NSArray<NSString *> *)pageIssues;

@end

/**
 *  Deprecated methods & properties
 */
@interface MWKArticle ()

/**
 *  @return Set of all image URLs shown in the receiver.
 */
- (NSSet<NSURL *> *)allImageURLs;

- (NSArray<NSURL *> *)imageURLsForGallery;

- (NSArray<MWKImage *> *)imagesForGallery;

- (NSArray<NSURL *> *)imageURLsForSaving;

@end
NS_ASSUME_NONNULL_END

//
//  MWKArticle.h
//  MediaWikiKit
//
//  Created by Brion on 10/7/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MWKSiteDataObject.h"

static const NSInteger kMWKArticleSectionNone = -1;

@class MWKDataStore;
@class MWKSection;
@class MWKSectionList;
@class MWKImage;
@class MWKImageList;
@class MWKProtectionStatus;

@interface MWKArticle : MWKSiteDataObject
{
    @protected
    MWKImageList* _images;
}
/// Data store used for reading & writing related entities.
@property (readonly, weak, nonatomic) MWKDataStore* dataStore;

// Identifiers
@property (readonly, strong, nonatomic) MWKTitle* title;

// Metadata
@property (readonly, strong, nonatomic) MWKTitle* redirected;                // optional
@property (readonly, strong, nonatomic) NSDate* lastmodified;                // required
@property (readonly, strong, nonatomic) MWKUser* lastmodifiedby;             // required
@property (readonly, assign, nonatomic) int articleId;                       // required; -> 'id'
@property (readonly, strong, nonatomic) NSNumber* revisionId;

/**
 * Number of links to other wikis on this page.
 *
 * This is *mostly* links to the same topic/entity in another language, but not always. See the comments
 * in LanguageLinksFetcher. Be sure to double check that you add special handling when necessary. For example, main
 * pages can have a misleading non-zero languagecount.
 */
@property (readonly, assign, nonatomic) int languagecount;

@property (readonly, copy, nonatomic) NSString* displaytitle;              // optional
@property (readonly, strong, nonatomic) MWKProtectionStatus* protection;     // required
@property (readonly, assign, nonatomic) BOOL editable;                       // required

/// Whether or not the receiver is the main page for its @c site.
@property (readonly, assign, nonatomic, getter = isMain) BOOL main;

@property (readwrite, copy, nonatomic) NSString* thumbnailURL;   // optional; pulled separately via search
@property (readwrite, copy, nonatomic) NSString* imageURL;       // optional; pulled in article request

- (NSString*)bestThumbnailImageURL;

@property (readonly, copy, nonatomic) NSString* entityDescription;            // optional; currently pulled separately via wikidata
@property (readonly, copy, nonatomic) NSString* searchSnippet; //Snippet returned from search results

@property (readonly, strong, nonatomic) MWKSectionList* sections;

@property (readonly, strong, nonatomic) MWKImageList* images;
@property (readonly, strong, nonatomic) MWKImage* thumbnail;
@property (readonly, strong, nonatomic) MWKImage* image;

@property (readonly, strong, nonatomic) NSString* summary;

- (MWKImage*)bestThumbnailImage;

/**
 *  Array of `MWKCitation` objects parsed from the receiver's reference list.
 *
 *  Might be `nil` if the section containing the reference list hasn't been downloaded, be sure to check `isCached`
 *  and fetch the full article contents if necessary.  Might also be `nil` if an error occurred, in which case the
 *  citations should be viewed in the webview.
 */
@property (readonly, strong, nonatomic /*, nullable*/) NSArray* citations;

- (instancetype)initWithTitle:(MWKTitle*)title dataStore:(MWKDataStore*)dataStore;
- (instancetype)initWithTitle:(MWKTitle*)title dataStore:(MWKDataStore*)dataStore dict:(NSDictionary*)dict;
- (instancetype)initWithTitle:(MWKTitle*)title dataStore:(MWKDataStore*)dataStore searchResultsDict:(NSDictionary*)dict;

/**
 * Import article and section metadata (and text if available)
 * from an API mobileview JSON response, save it to the database,
 * and make it available through this object.
 */
- (void)importMobileViewJSON:(NSDictionary*)jsonDict;

- (MWKImage*)imageWithURL:(NSString*)url;
- (MWKImage*)existingImageWithURL:(NSString*)url;

/**
 * Create a stub record for an image with given URL.
 */
- (MWKImage*)importImageURL:(NSString*)url sectionId:(int)sectionId;

/**
 *  Add the given URL to the receiver's image list, as well as to the corresponding section's image list.
 *
 *  @param sourceURL The URL string to add.
 *  @param sectionId The section whose image list the URL should also be added to.
 *  @param skipIfPresent @c YES if the image should only be added if the list doesn't contain it.
 */
- (void)appendImageListsWithSourceURL:(NSString*)sourceURL inSection:(int)sectionId skipIfPresent:(BOOL)skipIfPresent;

/**
 *  Add the given URL to the receiver's image list, as well as to the corresponding section's image list.
 *
 *  @param sourceURL The URL string to add.
 *  @param sectionId The section whose image list the URL should also be added to.
 *
 *  @see updateImageListsWithSourceURL:inSection:skipIfPresent:
 */
- (void)appendImageListsWithSourceURL:(NSString*)sourceURL inSection:(int)sectionId;

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
- (BOOL)isEqualToArticle:(MWKArticle*)article;

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
- (BOOL)isDeeplyEqualToArticle:(MWKArticle*)article;

- (void)save;

- (void)remove;

- (BOOL)isCached;


/**
 *  @return The HTML for the article (all of the sections)
 */
- (NSString*)articleHTML;

@end

@interface MWKArticle ()

/**
 * Import downloaded image data into our data store,
 * and update the image object/record
 */
- (MWKImage*)importImageData:(NSData*)data image:(MWKImage*)image WMF_TECH_DEBT_DEPRECATED;

/**
 *  @return Set of all image URLs shown in the receiver.
 */
- (NSSet<NSURL*>*)allImageURLs;

- (NSString*)summary;

- (nullable NSArray<MWKTitle*>*)disambiguationTitles;

- (nullable NSArray<NSString*>*)pageIssues;

@end

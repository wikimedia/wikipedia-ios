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

- (BOOL)isEqualToArticle:(MWKArticle*)article;
- (BOOL)isDeeplyEqualToArticle:(MWKArticle*)article;

- (void)save;
- (void)saveWithoutSavingSectionText;
- (void)remove;

- (BOOL)isCached;

///
/// @name Extraction
///

/**
 * @return Summary of the receiver as an attributd string built from HTML.
 */
- (NSAttributedString*)summaryHTML;

@end

@interface MWKArticle ()

/**
 * Import downloaded image data into our data store,
 * and update the image object/record
 */
- (MWKImage*)importImageData:(NSData*)data image:(MWKImage*)image __deprecated;

/**
 *  Loads the image in the "thumbnailURL" property from disk
 *  if it has been cached.
 */
- (void)loadThumbnailFromDisk __deprecated;

- (NSArray*)allImageURLs;

@end

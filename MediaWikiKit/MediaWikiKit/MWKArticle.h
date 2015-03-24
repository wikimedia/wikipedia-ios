//
//  MWKArticle.h
//  MediaWikiKit
//
//  Created by Brion on 10/7/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

static const NSInteger kMWKArticleSectionNone = -1;

#import <UIKit/UIKit.h>

#import "MWKSiteDataObject.h"

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

// Identifiers
@property (readonly) MWKSite* site;
@property (readonly) MWKTitle* title;
@property (readonly) MWKDataStore* dataStore;

// Metadata
@property (readonly) MWKTitle* redirected;                // optional
@property (readonly) NSDate* lastmodified;                // required
@property (readonly) MWKUser* lastmodifiedby;             // required
@property (readonly) int articleId;                       // required; -> 'id'
@property (readonly) int languagecount;                   // required; int
@property (readonly) NSString* displaytitle;              // optional
@property (readonly) MWKProtectionStatus* protection;     // required
@property (readonly) BOOL editable;                       // required

@property (readwrite, nonatomic) NSString* thumbnailURL;   // optional; pulled separately via search
@property (readwrite, nonatomic) NSString* imageURL;       // optional; pulled in article request

@property (readonly) NSString* entityDescription;            // optional; currently pulled separately via wikidata

@property (readonly) MWKSectionList* sections;

@property (readonly) MWKImageList* images;
@property (readonly) MWKImage* thumbnail;
@property (readonly) MWKImage* image;

@property (readwrite) BOOL needsRefresh;

- (instancetype)initWithTitle:(MWKTitle*)title dataStore:(MWKDataStore*)dataStore;
- (instancetype)initWithTitle:(MWKTitle*)title dataStore:(MWKDataStore*)dataStore dict:(NSDictionary*)dict;

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
 * Import downloaded image data into our data store,
 * and update the image object/record
 */
- (MWKImage*)importImageData:(NSData*)data image:(MWKImage*)image;

- (void)save;
- (void)saveWithoutSavingSectionText;
- (void)remove;

@end

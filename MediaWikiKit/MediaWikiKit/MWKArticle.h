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
@property (readonly, strong, nonatomic) MWKTitle* title;
@property (readonly, weak, nonatomic) MWKDataStore* dataStore;

// Metadata
@property (readonly, strong, nonatomic) MWKTitle* redirected;                // optional
@property (readonly, strong, nonatomic) NSDate* lastmodified;                // required
@property (readonly, strong, nonatomic) MWKUser* lastmodifiedby;             // required
@property (readonly, assign, nonatomic) int articleId;                       // required; -> 'id'
@property (readonly, assign, nonatomic) int languagecount;                   // required; int
@property (readonly, copy, nonatomic) NSString* displaytitle;              // optional
@property (readonly, strong, nonatomic) MWKProtectionStatus* protection;     // required
@property (readonly, assign, nonatomic) BOOL editable;                       // required

@property (readwrite, copy, nonatomic) NSString* thumbnailURL;   // optional; pulled separately via search
@property (readwrite, copy, nonatomic) NSString* imageURL;       // optional; pulled in article request

@property (readonly, copy, nonatomic) NSString* entityDescription;            // optional; currently pulled separately via wikidata

@property (readonly, strong, nonatomic) MWKSectionList* sections;

@property (readonly, strong, nonatomic) MWKImageList* images;
@property (readonly, strong, nonatomic) MWKImage* thumbnail;
@property (readonly, strong, nonatomic) MWKImage* image;

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

- (BOOL)isCached;

@end

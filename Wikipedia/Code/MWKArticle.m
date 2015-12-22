//
//  MWKArticle.m
//  MediaWikiKit
//
//  Created by Brion on 10/7/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "MediaWikiKit.h"
#import <hpple/TFHpple.h>
#import <BlocksKit/BlocksKit.h>
#import "WikipediaAppUtils.h"
#import "NSURL+Extras.h"
#import "NSString+WMFHTMLParsing.h"
#import "MWKCitation.h"
#import "MWKSection+DisplayHtml.h"

@import CoreText;

typedef NS_ENUM (NSUInteger, MWKArticleSchemaVersion) {
    /**
     * Initial schema verison, added @c main boolean field.
     */
    MWKArticleSchemaVersion_1 = 1
};

static MWKArticleSchemaVersion const MWKArticleCurrentSchemaVersion = MWKArticleSchemaVersion_1;

@interface MWKArticle ()

// Identifiers
@property (readwrite, strong, nonatomic) MWKTitle* title;
@property (readwrite, weak, nonatomic) MWKDataStore* dataStore;

// Metadata
@property (readwrite, strong, nonatomic) MWKTitle* redirected;                // optional
@property (readwrite, strong, nonatomic) NSDate* lastmodified;                // required
@property (readwrite, strong, nonatomic) MWKUser* lastmodifiedby;             // required
@property (readwrite, assign, nonatomic) int articleId;                       // required; -> 'id'
@property (readwrite, assign, nonatomic) int languagecount;                   // required; int
@property (readwrite, copy, nonatomic) NSString* displaytitle;              // optional
@property (readwrite, strong, nonatomic) MWKProtectionStatus* protection;     // required
@property (readwrite, assign, nonatomic) BOOL editable;                       // required
@property (readwrite, assign, nonatomic, getter = isMain) BOOL main;

@property (readwrite, copy, nonatomic) NSString* entityDescription;            // optional; currently pulled separately via wikidata
@property (readwrite, copy, nonatomic) NSString* snippet;

@property (readwrite, strong, nonatomic) MWKSectionList* sections;

@property (readwrite, strong, nonatomic) MWKImageList* images;
@property (readwrite, strong, nonatomic) MWKImage* thumbnail;
@property (readwrite, strong, nonatomic) MWKImage* image;
@property (readwrite, strong, nonatomic /*, nullable*/) NSArray* citations;
@property (readwrite, strong, nonatomic) NSString* summary;

@end

@implementation MWKArticle

#pragma mark - Setup / Tear Down

- (instancetype)initWithTitle:(MWKTitle*)title dataStore:(MWKDataStore*)dataStore {
    NSParameterAssert(title);
    self = [self initWithSite:title.site];
    if (self) {
        self.dataStore = dataStore;
        self.title     = title;
    }
    return self;
}

- (instancetype)initWithTitle:(MWKTitle*)title dataStore:(MWKDataStore*)dataStore dict:(NSDictionary*)dict {
    self = [self initWithTitle:title dataStore:dataStore];
    if (self) {
        [self importMobileViewJSON:dict];
    }
    return self;
}

- (instancetype)initWithTitle:(MWKTitle*)title dataStore:(MWKDataStore*)dataStore searchResultsDict:(NSDictionary*)dict {
    self = [self initWithTitle:title dataStore:dataStore];
    if (self) {
        self.entityDescription = [self optionalString:@"description" dict:dict];
        self.snippet           = [self optionalString:@"snippet" dict:dict];
        self.thumbnailURL      = dict[@"thumbnail"][@"source"];
        self.imageURL          = self.thumbnailURL;
    }

    return self;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    } else if ([object isKindOfClass:[MWKArticle class]]) {
        return [self isEqualToArticle:object];
    } else {
        return NO;
    }
}

- (BOOL)isEqualToArticle:(MWKArticle*)other {
    return WMF_EQUAL(self.title, isEqualToTitle:, other.title)
           && WMF_EQUAL(self.redirected, isEqual:, other.redirected)
           && WMF_EQUAL(self.lastmodified, isEqualToDate:, other.lastmodified)
           && WMF_IS_EQUAL(self.lastmodifiedby, other.lastmodifiedby)
           && WMF_EQUAL(self.displaytitle, isEqualToString:, other.displaytitle)
           && WMF_EQUAL(self.protection, isEqual:, other.protection)
           && WMF_EQUAL(self.thumbnailURL, isEqualToString:, other.thumbnailURL)
           && WMF_EQUAL(self.imageURL, isEqualToString:, other.imageURL)
           && self.articleId == other.articleId
           && self.languagecount == other.languagecount
           && self.isMain == other.isMain
           && self.images.count == other.images.count
           && self.sections.count == other.sections.count;
}

- (BOOL)isDeeplyEqualToArticle:(MWKArticle*)article {
    return [self isEqual:article]
           && WMF_IS_EQUAL(self.images, article.images)
           && WMF_IS_EQUAL(self.sections, article.sections);
}

- (NSString*)description {
    return [NSString stringWithFormat:@"%@ %@", [super description], self.title.description];
}

#pragma mark - Import / Export

- (id)dataExport {
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];

    dict[@"schemaVersion"] = @(MWKArticleCurrentSchemaVersion);

    if (self.redirected) {
        dict[@"redirected"] = self.redirected.text;
    }
    dict[@"lastmodified"] = [self iso8601DateString:self.lastmodified];
    if (!self.lastmodifiedby.anonymous) {
        dict[@"lastmodifiedby"] = [self.lastmodifiedby dataExport];
    }
    dict[@"id"]            = @(self.articleId);
    dict[@"languagecount"] = @(self.languagecount);
    if (self.displaytitle) {
        dict[@"displaytitle"] = self.displaytitle;
    }
    dict[@"protection"] = [self.protection dataExport];
    dict[@"editable"]   = @(self.editable);

    if (self.entityDescription) {
        dict[@"description"] = self.entityDescription;
    }

    if (self.thumbnailURL) {
        dict[@"thumbnailURL"] = self.thumbnailURL;
    }
    if (self.imageURL) {
        dict[@"imageURL"] = self.imageURL;
    }

    dict[@"mainpage"] = @(self.isMain);

    return [dict copy];
}

- (void)importMobileViewJSON:(NSDictionary*)dict {
    // uncomment when schema is bumped to perform migrations if necessary
//    MWKArticleSchemaVersion schemaVersion = [dict[@"schemaVersion"] unsignedIntegerValue];

    self.lastmodified   = [self requiredDate:@"lastmodified" dict:dict];
    self.lastmodifiedby = [self requiredUser:@"lastmodifiedby" dict:dict];
    self.articleId      = [[self requiredNumber:@"id" dict:dict] intValue];
    self.languagecount  = [[self requiredNumber:@"languagecount" dict:dict] intValue];
    self.protection     = [self requiredProtectionStatus:@"protection" dict:dict];
    self.editable       = [[self requiredNumber:@"editable" dict:dict] boolValue];

    self.redirected        = [self optionalTitle:@"redirected" dict:dict];
    self.displaytitle      = [self optionalString:@"displaytitle" dict:dict];
    self.entityDescription = [self optionalString:@"description" dict:dict];
    // From mobileview API...
    if (dict[@"thumb"]) {
        self.imageURL = dict[@"thumb"][@"url"]; // optional
    } else {
        // From local storage
        self.imageURL = [self optionalString:@"imageURL" dict:dict];
    }

    // From local storage
    self.thumbnailURL = [self optionalString:@"thumbnailURL" dict:dict];

    // Populate sections
    NSArray* sectionsData = [dict[@"sections"] bk_map:^id (NSDictionary* sectionData) {
        return [[MWKSection alloc] initWithArticle:self dict:sectionData];
    }];

    /*
       mainpage might be returned w/ old JSON boolean handling, check for both until 1.26wmf8 is deployed everywhere
     */
    id mainPageValue = dict[@"mainpage"];
    if (mainPageValue == nil) {
        // field not present due to "empty string" behavior (see below), or we're loading legacy cache data
        self.main = NO;
    } else if ([mainPageValue isKindOfClass:[NSString class]]) {
        // old mediawiki convention was to use a field w/ an empty string as "true" and omit the field for "false"
        NSAssert([mainPageValue length] == 0, @"Assuming empty string for boolean field.");
        self.main = YES;
    } else {
        // proper JSON boolean types!
        NSAssert([mainPageValue isKindOfClass:[NSNumber class]], @"Expected main page to be a boolean. Got %@", dict);
        self.main = [mainPageValue boolValue];
    }

    if ([sectionsData count] > 0) {
        self.sections = [[MWKSectionList alloc] initWithArticle:self sections:sectionsData];
    }
}

#pragma mark - Image Helpers

- (void)appendImageListsWithSourceURL:(NSString*)sourceURL inSection:(int)sectionId skipIfPresent:(BOOL)skipIfPresent {
    if (sourceURL && sourceURL.length > 0) {
        if (skipIfPresent) {
            [self.images addImageURLIfAbsent:sourceURL];
        } else {
            [self.images addImageURL:sourceURL];
        }
        if (sectionId != kMWKArticleSectionNone) {
            if (skipIfPresent) {
                [self.sections[sectionId].images addImageURLIfAbsent:sourceURL];
            } else {
                [self.sections[sectionId].images addImageURL:sourceURL];
            }
        }
    }
}

- (void)appendImageListsWithSourceURL:(NSString*)sourceURL inSection:(int)sectionId {
    [self appendImageListsWithSourceURL:sourceURL inSection:sectionId skipIfPresent:NO];
}

/**
 * Create a stub record for an image with given URL.
 */
- (MWKImage*)importImageURL:(NSString*)url sectionId:(int)sectionId {
    [self appendImageListsWithSourceURL:url inSection:sectionId];
    return [[MWKImage alloc] initWithArticle:self sourceURLString:url];
}

/**
 * Import downloaded image data into our data store,
 * and update the image object/record
 */
- (MWKImage*)importImageData:(NSData*)data image:(MWKImage*)image {
    [self.dataStore saveImageData:data image:image];
    return image;
}

- (MWKImage*)imageWithURL:(NSString*)url {
    return [self.dataStore imageWithURL:url article:self];
}

- (NSString*)bestThumbnailImageURL {
    if (self.thumbnailURL) {
        return self.thumbnailURL;
    }

    if (self.imageURL) {
        return self.imageURL;
    }

    return nil;
}

/**
 * Return image object if folder for that image exists
 * else return nil
 */
- (MWKImage*)existingImageWithURL:(NSString*)url {
    NSString* imageCacheFolderPath = [self.dataStore pathForImageURL:url title:self.title];
    if (!imageCacheFolderPath) {
        return nil;
    }

    BOOL imageCacheFolderPathExists = [[NSFileManager defaultManager] fileExistsAtPath:imageCacheFolderPath isDirectory:NULL];
    if (!imageCacheFolderPathExists) {
        return nil;
    }

    return [self imageWithURL:url];
}

#pragma mark - Save

- (void)save {
    [self.dataStore saveArticle:self];
    [self.images save];
    [self.sections save];
}

#pragma mark - Remove

- (void)remove {
    [self.dataStore deleteArticle:self];
    // reset ivars to prevent state from persisting in memory
    self.sections = nil;
    self.images   = nil;
}

#pragma mark - Accessors

- (MWKSectionList*)sections {
    if (_sections == nil) {
        _sections = [[MWKSectionList alloc] initWithArticle:self];
    }
    return _sections;
}

- (BOOL)isCached {
    if ([self.sections count] == 0) {
        return NO;
    }
    for (MWKSection* section in self.sections) {
        if (![section hasTextData]) {
            return NO;
        }
    }
    return YES;
}

- (MWKImage*)thumbnail {
    if (self.thumbnailURL && !_thumbnail) {
        _thumbnail = [self imageWithURL:self.thumbnailURL];
    }
    return _thumbnail;
}

- (void)setThumbnailURL:(NSString*)thumbnailURL {
    _thumbnailURL = thumbnailURL;
    [self.images addImageURLIfAbsent:thumbnailURL];
}

- (void)setImageURL:(NSString*)imageURL {
    _imageURL = imageURL;
    [self.images addImageURLIfAbsent:imageURL];
}

- (MWKImage*)image {
    if (self.imageURL && !_image) {
        _image = [self imageWithURL:self.imageURL];
    }
    return _image;
}

- (MWKImage*)bestThumbnailImage {
    if (self.thumbnailURL) {
        return [self thumbnail];
    }

    if (self.imageURL) {
        return [self image];
    }

    return nil;
}

- (MWKImageList*)images {
    if (_images == nil) {
        _images = [self.dataStore imageListWithArticle:self section:nil];
    }
    return _images;
}

#pragma mark - protection status methods

- (MWKProtectionStatus*)requiredProtectionStatus:(NSString*)key dict:(NSDictionary*)dict {
    NSDictionary* obj = [self requiredDictionary:key dict:dict];
    if (obj == nil) {
        @throw [NSException exceptionWithName:@"MWKDataObjectException"
                                       reason:@"missing required protection status field"
                                     userInfo:@{@"key": key}];
    } else {
        return [[MWKProtectionStatus alloc] initWithData:obj];
    }
}

- (NSString*)debugDescription {
    return [NSString stringWithFormat:@"%@ { \n"
            "\tlastModifiedBy: %@, \n"
            "\tlastModified: %@, \n"
            "\tarticleId: %d, \n"
            "\tlanguageCount: %d, \n"
            "\tdisplayTitle: %@, \n"
            "\tprotection: %@, \n"
            "\teditable: %d, \n"
            "\tthumbnailURL: %@, \n"
            "\timageURL: %@, \n"
            "\tsections: %@, \n"
            "\timages: %@, \n"
            "\tentityDescription: %@, \n"
            "}",
            self.description,
            self.lastmodifiedby,
            self.lastmodified,
            self.articleId,
            self.languagecount,
            self.displaytitle,
            self.protection,
            self.editable,
            self.thumbnailURL,
            self.imageURL,
            self.sections.debugDescription,
            self.images.debugDescription,
            self.entityDescription];
}

- (NSSet<NSURL*>*)allImageURLs {
    NSMutableSet<NSURL*>* imageURLs = [NSMutableSet setWithArray:
                                       [self.images.entries bk_map:^NSURL*(NSString* sourceURL) {
        return [NSURL URLWithString:sourceURL];
    }]];

    [imageURLs addObjectsFromArray:
     [[self.dataStore imageInfoForTitle:self.title] valueForKey:WMF_SAFE_KEYPATH(MWKImageInfo.new, canonicalFileURL)]];

    [imageURLs addObjectsFromArray:
     [[self.dataStore imageInfoForTitle:self.title] valueForKey:WMF_SAFE_KEYPATH(MWKImageInfo.new, imageThumbURL)]];

    NSURL* articleImageURL = [NSURL wmf_optionalURLWithString:self.imageURL];
    if (articleImageURL) {
        [imageURLs addObject:articleImageURL];
    }

    NSURL* articleThumbnailURL = [NSURL wmf_optionalURLWithString:self.thumbnailURL];
    if (articleThumbnailURL) {
        [imageURLs addObject:articleThumbnailURL];
    }

    // remove any null objects inserted during above map/valueForKey operations
    return [imageURLs bk_reject:^BOOL (id obj) {
        return [NSNull null] == obj;
    }];
}

#pragma mark - Extraction

#pragma mark Citations

static NSString* const WMFArticleReflistColumnSelector = @"/html/body/*[contains(@class,'reflist')]//*[contains(@class, 'references')]/li";

- (NSArray*)citations {
    if (!_citations) {
        __block NSArray* referenceListItems;
        [self.sections.entries enumerateObjectsWithOptions:NSEnumerationReverse
                                                usingBlock:^(MWKSection* section, NSUInteger idx, BOOL* stop) {
            referenceListItems = [section elementsInTextMatchingXPath:WMFArticleReflistColumnSelector];
            if (referenceListItems.count > 0) {
                *stop = YES;
            }
        }];
        if (!referenceListItems) {
            DDLogWarn(@"Failed to parse reflist for %@ cached article: %@", self.isCached ? @"" : @"not", self);
            return nil;
        }
        _citations = [[referenceListItems bk_map:^MWKCitation*(TFHppleElement* el) {
            return [[MWKCitation alloc] initWithCitationIdentifier:el.attributes[@"id"]
                                                           rawHTML:el.raw];
        }] bk_reject:^BOOL (id obj) {
            return WMF_IS_EQUAL(obj, [NSNull null]);
        }];
    }
    return _citations;
}

#pragma mark Section Paragraphs

- (NSString*)summary {
    if (_summary) {
        return _summary;
    }

    for (MWKSection* section in self.sections) {
        NSString* summary = [section summary];
        if (summary) {
            _summary = summary;
            return summary;
        }
    }
    return nil;
}

- (NSString*)articleHTML {
    NSMutableArray* sectionTextArray = [[NSMutableArray alloc] init];

    for (MWKSection* section in self.sections) {
        // Structural html added around section html just before display.
        NSString* sectionHTMLWithID = [section displayHTML];
        [sectionTextArray addObject:sectionHTMLWithID];
    }

    // Join article sections text
    NSString* joint   = @"";     //@"<div style=\"height:20px;\"></div>";
    NSString* htmlStr = [sectionTextArray componentsJoinedByString:joint];

    return htmlStr;
}

- (nullable NSArray<MWKTitle*>*)disambiguationTitles {
    return [[self.sections.entries firstObject] disambiguationTitles];
}

- (nullable NSArray<NSString*>*)pageIssues {
    return [[self.sections.entries firstObject] pageIssues];
}

@end

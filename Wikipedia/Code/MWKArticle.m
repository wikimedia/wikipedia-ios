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
#import "NSString+WMFHTMLParsing.h"
#import "MWKCitation.h"
#import "MWKSection+DisplayHtml.h"
#import "NSMutableDictionary+WMFMaybeSet.h"
#import "WMFImageURLParsing.h"
#import "UIScreen+WMFImageWidth.h"

#import "WMFImageTagParser.h"
#import "WMFImageTagList.h"
#import "WMFImageTagList+ImageURLs.h"

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
@property (readwrite, weak, nonatomic) MWKDataStore* dataStore;

// Metadata
@property (readwrite, strong, nonatomic) NSURL* redirectedURL;                // optional
@property (readwrite, strong, nonatomic) NSDate* lastmodified;                // optional
@property (readwrite, strong, nonatomic) MWKUser* lastmodifiedby;             // required
@property (readwrite, assign, nonatomic) int articleId;                       // required; -> 'id'
@property (readwrite, assign, nonatomic) int languagecount;                   // required; int
@property (readwrite, copy, nonatomic) NSString* displaytitle;              // optional
@property (readwrite, strong, nonatomic) MWKProtectionStatus* protection;     // required
@property (readwrite, assign, nonatomic) BOOL editable;                       // required
@property (readwrite, assign, nonatomic, getter = isMain) BOOL main;
@property (readwrite, strong, nonatomic) NSNumber* revisionId;

@property (readwrite, copy, nonatomic) NSString* entityDescription;            // optional; currently pulled separately via wikidata
@property (readwrite, copy, nonatomic) NSString* snippet;

@property (readwrite, strong, nonatomic) MWKSectionList* sections;

@property (readwrite, strong, nonatomic) MWKImage* thumbnail;
@property (readwrite, strong, nonatomic) MWKImage* image;
@property (readwrite, strong, nonatomic /*, nullable*/) NSArray* citations;
@property (readwrite, strong, nonatomic) NSString* summary;

@end

@implementation MWKArticle

#pragma mark - Setup / Tear Down

- (instancetype)initWithURL:(NSURL*)url dataStore:(MWKDataStore*)dataStore {
    NSParameterAssert(url.wmf_title);
    self = [self initWithURL:[url wmf_URLWithFragment:nil]];
    if (self) {
        self.dataStore = dataStore;
    }
    return self;
}

- (instancetype)initWithURL:(NSURL*)url dataStore:(MWKDataStore*)dataStore dict:(NSDictionary*)dict {
    self = [self initWithURL:url dataStore:dataStore];
    if (self) {
        [self importMobileViewJSON:dict];
    }
    return self;
}

- (instancetype)initWithURL:(NSURL*)url dataStore:(MWKDataStore*)dataStore searchResultsDict:(NSDictionary*)dict {
    self = [self initWithURL:url dataStore:dataStore];
    if (self) {
        self.entityDescription = [self optionalString:@"description" dict:dict];
        self.snippet           = [self optionalString:@"snippet" dict:dict];
        self.imageURL          = dict[@"thumbnail"][@"source"];
        self.thumbnailURL      = [self thumbnailURLFromImageURL:self.imageURL];
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
    return WMF_EQUAL(self.url, isEqual:, other.url)
           && WMF_EQUAL(self.redirectedURL, isEqual:, other.redirectedURL)
           && WMF_EQUAL(self.lastmodified, isEqualToDate:, other.lastmodified)
           && WMF_IS_EQUAL(self.lastmodifiedby, other.lastmodifiedby)
           && WMF_EQUAL(self.displaytitle, isEqualToString:, other.displaytitle)
           && WMF_EQUAL(self.protection, isEqual:, other.protection)
           && WMF_EQUAL(self.thumbnailURL, isEqualToString:, other.thumbnailURL)
           && WMF_EQUAL(self.imageURL, isEqualToString:, other.imageURL)
           && WMF_EQUAL(self.revisionId, isEqualToNumber:, other.revisionId)
           && self.articleId == other.articleId
           && self.languagecount == other.languagecount
           && self.isMain == other.isMain
           && self.sections.count == other.sections.count;
}

- (BOOL)isDeeplyEqualToArticle:(MWKArticle*)article {
    return [self isEqual:article]
           && WMF_IS_EQUAL(self.sections, article.sections);
}

- (NSUInteger)hash {
    return self.url.hash
           ^ flipBitsWithAdditionalRotation(self.revisionId.hash, 1)
           ^ flipBitsWithAdditionalRotation(self.lastmodified.hash, 2);
}

- (NSString*)description {
    return [NSString stringWithFormat:@"%@ %@", [super description], self.url.description];
}

#pragma mark - Import / Export

- (id)dataExport {
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];

    dict[@"schemaVersion"] = @(MWKArticleCurrentSchemaVersion);

    [dict wmf_maybeSetObject:self.redirectedURL.wmf_title forKey:@"redirect"];

    [dict wmf_maybeSetObject:[self iso8601DateString:self.lastmodified] forKey:@"lastmodified"];

    if (!self.lastmodifiedby.anonymous) {
        dict[@"lastmodifiedby"] = [self.lastmodifiedby dataExport];
    }

    dict[@"id"]            = @(self.articleId);
    dict[@"languagecount"] = @(self.languagecount);

    [dict wmf_maybeSetObject:self.displaytitle forKey:@"displaytitle"];

    dict[@"protection"] = [self.protection dataExport];
    dict[@"editable"]   = @(self.editable);

    [dict wmf_maybeSetObject:self.entityDescription forKey:@"description"];

    [dict wmf_maybeSetObject:self.thumbnailURL forKey:@"thumbnailURL"];

    [dict wmf_maybeSetObject:self.imageURL forKey:@"imageURL"];

    [dict wmf_maybeSetObject:self.revisionId forKey:@"revision"];

    dict[@"mainpage"] = @(self.isMain);

    return [dict copy];
}

- (void)importMobileViewJSON:(NSDictionary*)dict {
    // uncomment when schema is bumped to perform migrations if necessary
//    MWKArticleSchemaVersion schemaVersion = [dict[@"schemaVersion"] unsignedIntegerValue];

    self.lastmodified   = [self optionalDate:@"lastmodified" dict:dict];
    self.lastmodifiedby = [self requiredUser:@"lastmodifiedby" dict:dict];
    self.articleId      = [[self requiredNumber:@"id" dict:dict] intValue];
    self.languagecount  = [[self requiredNumber:@"languagecount" dict:dict] intValue];


    //We are getting crashes becuase of the protection status.
    //Set this up
    @try {
        self.protection = [self requiredProtectionStatus:@"protection" dict:dict];
    } @catch (NSException* exception) {
        self.protection = nil;
        DDLogWarn(@"Protection Status is not a dictionary, setting to nil: %@", [[dict valueForKey:@"protection"] description]);
    }

    self.editable = [[self requiredNumber:@"editable" dict:dict] boolValue];

    self.revisionId        = [self optionalNumber:@"revision" dict:dict];
    self.redirectedURL     = [self optionalURL:@"redirected" dict:dict];
    self.displaytitle      = [self optionalString:@"displaytitle" dict:dict];
    self.entityDescription = [self optionalString:@"description" dict:dict];
    // From mobileview API...
    if (dict[@"thumb"]) {
        self.imageURL = dict[@"thumb"][@"url"]; // optional
    } else {
        // From local storage
        self.imageURL = [self optionalString:@"imageURL" dict:dict];
    }

    self.thumbnailURL = [self thumbnailURLFromImageURL:self.imageURL];

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
    NSString* imageCacheFolderPath = [self.dataStore pathForImageURL:url forArticleURL:self.url];
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
    [self.sections save];
}

#pragma mark - Remove

- (void)remove {
    [self.dataStore deleteArticle:self];
    // reset ivars to prevent state from persisting in memory
    self.sections = nil;
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

- (NSString*)thumbnailURLFromImageURL:(NSString*)imageURL {
    return WMFChangeImageSourceURLSizePrefix(imageURL, [[UIScreen mainScreen] wmf_listThumbnailWidthForScale].unsignedIntegerValue);
}

- (void)setThumbnailURL:(NSString*)thumbnailURL {
    _thumbnailURL = thumbnailURL;
}

- (void)setImageURL:(NSString*)imageURL {
    _imageURL = imageURL;
}

- (MWKImage*)image {
    if (self.imageURL && !_image) {
        _image = [self imageWithURL:self.imageURL];
    }
    return _image;
}

- (MWKImage*)leadImage {
    if (self.imageURL) {
        return [self image];
    }

    if (self.thumbnailURL) {
        return [self thumbnail];
    }
    return nil;
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

- (BOOL)hasMultipleLanguages {
    if (self.isMain) {
        return NO;
    }
    return self.languagecount > 0;
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
            self.entityDescription];
}

#pragma mark - Images

- (NSArray<NSURL*>*)imageURLsForGallery {
    WMFImageTagList* tagList = [[[WMFImageTagParser alloc] init] imageTagListFromParsingHTMLString:self.articleHTML withBaseURL:self.url leadImageURL:self.leadImage.sourceURL];
    NSArray *imageURLs = [tagList imageURLsForGallery];
    if (imageURLs.count == 0 && self.imageURL) {
        NSString *imageURLString = [self.imageURL copy];
        if (imageURLString != nil) {
            NSURL *imageURL = [NSURL URLWithString:imageURLString];
            if (imageURL != nil) {
                imageURLs = @[imageURL];
            }
        }
    }
    return imageURLs;
}

- (NSArray<MWKImage*>*)imagesForGallery {
    return [[self imageURLsForGallery] bk_map:^id (NSURL* url){
        return [[MWKImage alloc] initWithArticle:self sourceURL:url];
    }];
}

- (NSArray<NSURL*>*)imageURLsForSaving {
    WMFImageTagList* tagList = [[[WMFImageTagParser alloc] init] imageTagListFromParsingHTMLString:self.articleHTML withBaseURL:self.url];
    return [tagList imageURLsForSaving];
}

- (NSArray<MWKImage*>*)imagesForSaving {
    return [[self imageURLsForSaving] bk_map:^id (NSURL* url){
        return [[MWKImage alloc] initWithArticle:self sourceURL:url];
    }];
}

- (NSArray<NSURL*>*)schemelessURLsRejectingNilURLs:(NSArray<NSURL*>*)urls {
    return [urls wmf_mapAndRejectNil:^NSURL*(NSURL* url){
        if ([url isKindOfClass:[NSURL class]]) {
            return [url wmf_schemelessURL];
        } else {
            return nil;
        }
    }];
}

- (NSSet<NSURL*>*)allImageURLs {
    WMFImageTagList* tagList = [[[WMFImageTagParser alloc] init] imageTagListFromParsingHTMLString:self.articleHTML withBaseURL:self.url];
    NSMutableSet<NSURL*>* imageURLs = [[NSMutableSet alloc] init];
    //Note: use the 'imageURLsForGallery' and 'imageURLsForSaving' methods on WMFImageTagList so we don't have to parse twice.
    [imageURLs addObjectsFromArray:[tagList imageURLsForGallery]];
    [imageURLs addObjectsFromArray:[tagList imageURLsForSaving]];

    NSArray<MWKImageInfo*>* infos = [self.dataStore imageInfoForArticleWithURL:self.url];

    NSArray<NSURL*>* lazilyFetchedHighResolutionGalleryImageURLs = [infos wmf_mapAndRejectNil:^id _Nullable (MWKImageInfo* _Nonnull obj) {
        if ([obj isKindOfClass:[MWKImageInfo class]]) {
            return [obj canonicalFileURL];
        } else {
            return nil;
        }
    }];

    [imageURLs addObjectsFromArray:[self schemelessURLsRejectingNilURLs:lazilyFetchedHighResolutionGalleryImageURLs]];

    NSArray<NSURL*>* thumbURLs = [infos wmf_mapAndRejectNil:^id _Nullable (MWKImageInfo* _Nonnull obj) {
        if ([obj isKindOfClass:[MWKImageInfo class]]) {
            return [obj imageThumbURL];
        } else {
            return nil;
        }
    }];

    [imageURLs addObjectsFromArray:[self schemelessURLsRejectingNilURLs:thumbURLs]];

    NSURL* articleImageURL = [NSURL wmf_optionalURLWithString:self.imageURL];
    [imageURLs wmf_safeAddObject:articleImageURL];

    NSURL* articleThumbnailURL = [NSURL wmf_optionalURLWithString:self.thumbnailURL];
    [imageURLs wmf_safeAddObject:articleThumbnailURL];

#if DEBUG
    for (NSURL* url in imageURLs) {
        NSAssert(url.scheme == nil, @"Non nil image url scheme detected! These must be nil here or we can get duplicate image urls in the set - ie the same url twice - once with the scheme and once without. This is because WMFImageTagParser returns urls without schemes because the html it parses does not have schemes - but the MWKImageInfo *does* have schemes in its 'canonicalFileURL' and 'imageThumbURL' properties because the api returns schemes.");
    }
#endif

    // remove any null objects inserted during above map/valueForKey operations
    return [imageURLs bk_reject:^BOOL (id obj) {
        return [obj isEqual:[NSNull null]];
    }];
}

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

- (nullable NSArray<NSURL*>*)disambiguationURLs {
    return [[self.sections.entries firstObject] disambiguationURLs];
}

- (nullable NSArray<NSString*>*)pageIssues {
    return [[self.sections.entries firstObject] pageIssues];
}

@end

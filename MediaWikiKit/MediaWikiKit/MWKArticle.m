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
#import "NSAttributedString+WMFHTMLForSite.h"
#import "MWKSection.h"

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
    return WMF_EQUAL(self.site, isEqualToSite:, other.site)
           && WMF_EQUAL(self.redirected, isEqual:, other.redirected)
           && WMF_EQUAL(self.lastmodified, isEqualToDate:, other.lastmodified)
           && WMF_IS_EQUAL(self.lastmodifiedby, other.lastmodifiedby)
           && WMF_EQUAL(self.displaytitle, isEqualToString:, other.displaytitle)
           && WMF_EQUAL(self.protection, isEqual:, other.protection)
           && WMF_EQUAL(self.thumbnailURL, isEqualToString:, other.thumbnailURL)
           && WMF_EQUAL(self.imageURL, isEqualToString:, other.imageURL)
           && self.articleId == other.articleId
           && self.languagecount == other.languagecount
           && self.isMain == other.isMain;
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

- (void)updateImageListsWithSourceURL:(NSString*)sourceURL inSection:(int)sectionId {
    if (sourceURL && sourceURL.length > 0) {
        [self.images addImageURL:sourceURL];
        if (sectionId != kMWKArticleSectionNone) {
            [self.sections[sectionId].images addImageURL:sourceURL];
        }
    }
}

/**
 * Create a stub record for an image with given URL.
 */
- (MWKImage*)importImageURL:(NSString*)url sectionId:(int)sectionId {
    [self updateImageListsWithSourceURL:url inSection:sectionId];
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

- (void)loadThumbnailFromDisk {
    /**
     *  The folowing logic was pulled from the Article Fetcher
     *  Putting it here to begin to coalesce populating Article data
     *  in a single place. This will be addressed natuarlly as we
     *  refactor model class mapping in the network layer.
     */
    if (!self.thumbnailURL) {
        return;
    }

    if ([[self existingImageWithURL:self.thumbnailURL] isDownloaded]) {
        return;
    }

    NSString* cacheFilePath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)
                                firstObject]
                               stringByAppendingPathComponent:self.thumbnailURL.lastPathComponent];
    BOOL isDirectory      = NO;
    BOOL cachedFileExists = [[NSFileManager defaultManager] fileExistsAtPath:cacheFilePath
                                                                 isDirectory:&isDirectory];
    if (cachedFileExists) {
        NSError* error = nil;
        NSData* data   = [NSData dataWithContentsOfFile:cacheFilePath options:0 error:&error];
        if (!error) {
            // Copy Search/Nearby thumb binary to core data store so it doesn't have to be re-downloaded.
            MWKImage* image = [self importImageURL:self.thumbnailURL sectionId:kMWKArticleSectionNone];
            [self importImageData:data image:image];
        }
    }
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

- (void)saveWithoutSavingSectionText {
    [self.dataStore saveArticle:self];
    [self.images save];
    for (MWKSection* section in self.sections) {
        if (section.images) {
            [section.images save];
        }
    }
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
    BOOL hasNilSection = NO;
    for (MWKSection* section in self.sections) {
        if (section.text == nil) {
            hasNilSection = YES;
            break;
        }
    }

    return [self.sections count] == 0 || hasNilSection ? NO : YES;
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

- (NSArray*)allImageURLs {
    NSMutableArray* imageURLs = [[self.images.entries bk_map:^NSURL*(NSString* sourceURL) {
        return [NSURL URLWithString:sourceURL];
    }] mutableCopy];

    [imageURLs addObjectsFromArray:
     [[self.dataStore imageInfoForArticle:self] valueForKey:WMF_SAFE_KEYPATH(MWKImageInfo.new, imageURL)]];

    [imageURLs addObjectsFromArray:
     [[self.dataStore imageInfoForArticle:self] valueForKey:WMF_SAFE_KEYPATH(MWKImageInfo.new, imageThumbURL)]];

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

static NSString* const WMFParagraphSelector = @"/html/body/p";

+ (NSString*)paragraphChildSelector {
    static NSString* paragraphChildSelector;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray* allowedTags = @[
            @"b",
            @"i",
            @"span",
            @"a",
            @"sup",
            @"blockquote",
            @"br",
            @"cite",
            @"em",
            @"header",
            @"h1",
            @"h2",
            @"h3",
            @"h4",
            @"h5",
            @"h6",
            @"ul",
            @"li",
            @"ol",
            @"q",
            @"strike",
            @"sub",
            @"u",
            @"ul"
        ];

        NSString* tagSelector = [[allowedTags bk_map:^NSString*(NSString* tag) {
            return [@"self::" stringByAppendingString:tag];
        }] componentsJoinedByString:@" or "];

        paragraphChildSelector = [NSString stringWithFormat:
                                  // top-level article paragraphs' text and
                                  @"%@/text() | "
                                  // children of top-level article paragraphs which is
                                  "%@/*["
                                  // one of allowed tags
                                  "(%@)"
                                  " and "
                                  // excluding geo-coordinates
                                  "not(*[@id = 'coordinates'])]"
                                  , WMFParagraphSelector, WMFParagraphSelector, tagSelector];
    });
    return paragraphChildSelector;
}

- (NSAttributedString*)summaryHTML {
    MWKSection* leadSection      = [self.sections firstNonEmptySection];
    NSString* filteredParagraphs =
        [[[[leadSection elementsInTextMatchingXPath:WMFParagraphSelector] bk_map:^NSString*(TFHppleElement* paragraphEl) {
        return [[[[TFHpple hppleWithHTMLData:[paragraphEl.raw dataUsingEncoding:NSUTF8StringEncoding]]
                  // select children of each paragraph
                  searchWithXPathQuery:[MWKArticle paragraphChildSelector]]
                 // get their "raw" HTML
                 valueForKey:WMF_SAFE_KEYPATH(paragraphEl, raw)]
                // join
                componentsJoinedByString:@""];
    }] bk_select:^BOOL (id stringOrNull) {
        return [stringOrNull isKindOfClass:[NSString class]] && [stringOrNull length] > 0;
    }]
         // double space all paragraphs
         componentsJoinedByString:@"<br/><br/>"];
    NSData* xpathData = [filteredParagraphs dataUsingEncoding:NSUTF8StringEncoding];
    return [[NSAttributedString alloc] initWithHTMLData:xpathData site:self.site];
}

@end

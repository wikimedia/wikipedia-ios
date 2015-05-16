//
//  MWKArticle.m
//  MediaWikiKit
//
//  Created by Brion on 10/7/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "MediaWikiKit.h"
#import <BlocksKit/BlocksKit.h>

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

@property (readwrite, copy, nonatomic) NSString* entityDescription;            // optional; currently pulled separately via wikidata

@property (readwrite, strong, nonatomic) MWKSectionList* sections;

@property (readwrite, strong, nonatomic) MWKImageList* images;
@property (readwrite, strong, nonatomic) MWKImage* thumbnail;
@property (readwrite, strong, nonatomic) MWKImage* image;

@end

@implementation MWKArticle

#pragma mark - Setup / Tear Down

- (instancetype)initWithTitle:(MWKTitle*)title dataStore:(MWKDataStore*)dataStore {
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

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
    if (object == nil) {
        return NO;
    } else if (![object isKindOfClass:[MWKArticle class]]) {
        return NO;
    } else {
        MWKArticle* other = object;
        return [self.site isEqual:other.site] &&
               (self.redirected == other.redirected || [self.redirected isEqual:other.redirected]) &&
               [self.lastmodified isEqual:other.lastmodified] &&
               [self.lastmodifiedby isEqual:other.lastmodifiedby] &&
               self.articleId == other.articleId &&
               self.languagecount == other.languagecount &&
               [self.displaytitle isEqualToString:other.displaytitle] &&
               [self.protection isEqual:other.protection] &&
               self.editable == other.editable &&
               (self.thumbnailURL == other.thumbnailURL || [self.thumbnailURL isEqualToString:other.thumbnailURL]) &&
               (self.imageURL == other.imageURL || [self.imageURL isEqualToString:other.imageURL]);
    }
}

- (NSString*)description {
    return [NSString stringWithFormat:@"%@ %@", [super description], self.title.description];
}

#pragma mark - Import / Export

- (id)dataExport {
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];

    if (self.redirected) {
        dict[@"redirected"] = self.redirected.prefixedText;
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
        // Note we call the property .entityDescription because [x description] is in use in Obj-C.
        dict[@"description"] = self.entityDescription;
    }

    if (self.thumbnailURL) {
        dict[@"thumbnailURL"] = self.thumbnailURL;
    }
    if (self.imageURL) {
        dict[@"imageURL"] = self.imageURL;
    }

    return [NSDictionary dictionaryWithDictionary:dict];
}

- (void)importMobileViewJSON:(NSDictionary*)dict {
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
    return [[MWKImage alloc] initWithArticle:self sourceURL:url];
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

/**
 * Return image object if folder for that image exists
 * else return nil
 */
- (MWKImage*)existingImageWithURL:(NSString*)url {
    NSString* thisImageCacheFolderPath  = [self.dataStore pathForImageURL:url title:self.title];
    BOOL isDirectory                    = NO;
    BOOL thisImageCacheFolderPathExists = [[NSFileManager defaultManager] fileExistsAtPath:thisImageCacheFolderPath isDirectory:&isDirectory];
    if (!thisImageCacheFolderPathExists) {
        return nil;
    } else {
        return [self imageWithURL:url];
    }
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
    NSString* path = [self.dataStore pathForArticle:self];
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
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
    return [self.sections count] > 0 ? YES : NO;
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

@end

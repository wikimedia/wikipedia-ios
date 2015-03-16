//
//  MWKArticle.m
//  MediaWikiKit
//
//  Created by Brion on 10/7/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "MediaWikiKit.h"
#import <BlocksKit/BlocksKit.h>

@implementation MWKArticle {
    MWKImageList* _images;
    MWKSectionList* _sections;
}

- (instancetype)initWithTitle:(MWKTitle*)title dataStore:(MWKDataStore*)dataStore {
    self = [self initWithSite:title.site];
    if (self) {
        _dataStore = dataStore;
        _title     = title;
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

- (void)importMobileViewJSON:(NSDictionary*)dict {
    _redirected        = [self optionalTitle:@"redirected"     dict:dict];
    _lastmodified      = [self requiredDate:@"lastmodified"   dict:dict];
    _lastmodifiedby    = [self requiredUser:@"lastmodifiedby" dict:dict];
    _articleId         = [[self requiredNumber:@"id"             dict:dict] intValue];
    _languagecount     = [[self requiredNumber:@"languagecount"  dict:dict] intValue];
    _displaytitle      = [self optionalString:@"displaytitle"   dict:dict];
    _protection        = [self requiredProtectionStatus:@"protection"     dict:dict];
    _editable          = [[self requiredNumber:@"editable"       dict:dict] boolValue];
    _entityDescription = [self optionalString:@"description"     dict:dict];

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
    NSArray* sectionsData = dict[@"sections"];

    sectionsData = [sectionsData bk_map:^id (NSDictionary* sectionData) {
        return [[MWKSection alloc] initWithArticle:self dict:sectionData];
    }];

    if ([sectionsData count] > 0) {
        [self.sections setSections:sectionsData];
    }
}

/**
 * Create a stub record for an image with given URL.
 */
- (MWKImage*)importImageURL:(NSString*)url sectionId:(int)sectionId {
    [self.images addImageURL:url];
    if (sectionId != kMWKArticleSectionNone) {
        [self.sections[sectionId].images addImageURL:url];
    }

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

- (void)setNeedsRefresh:(BOOL)val {
    NSString* filePath = [self.dataStore pathForArticle:self];
    NSString* fileName = [filePath stringByAppendingPathComponent:@"needsRefresh.lock"];

    if (val) {
        NSString* payload = @"needsRefresh";

        [[NSFileManager defaultManager] createDirectoryAtPath:filePath
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:nil];

        [payload writeToFile:fileName atomically:YES encoding:NSUTF8StringEncoding error:nil];
    } else {
        [[NSFileManager defaultManager] removeItemAtPath:fileName error:nil];
    }
}

- (BOOL)needsRefresh {
    NSString* filePath = [self.dataStore pathForArticle:self];
    NSString* fileName = [filePath stringByAppendingPathComponent:@"needsRefresh.lock"];
    return [[NSFileManager defaultManager] fileExistsAtPath:fileName isDirectory:nil];
}

- (void)save {
    [self.dataStore saveArticle:self];
    [self.images save];
    [self.sections save];
}

- (void)remove {
    NSString* path = [self.dataStore pathForArticle:self];
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];

    _sections = nil;
    _images   = nil;
}

- (MWKSectionList*)sections {
    if (_sections == nil) {
        _sections = [[MWKSectionList alloc] initWithArticle:self];
    }
    return _sections;
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

- (MWKImage*)thumbnail {
    if (self.thumbnailURL) {
        return [self imageWithURL:self.thumbnailURL];
    } else {
        return nil;
    }
}

- (void)setThumbnailURL:(NSString*)thumbnailURL {
    _thumbnailURL = thumbnailURL;
    if (thumbnailURL) {
        (void)[self importImageURL:thumbnailURL sectionId:kMWKArticleSectionNone];
    }
}

- (void)setImageURL:(NSString*)imageURL {
    _imageURL = imageURL;
    if (imageURL) {
        (void)[self importImageURL:imageURL sectionId:kMWKArticleSectionNone];
    }
}

- (MWKImage*)image {
    if (self.imageURL) {
        return [self imageWithURL:self.imageURL];
    } else {
        return nil;
    }
}

- (MWKImageList*)images {
    if (_images == nil) {
        _images = [self.dataStore imageListWithArticle:self section:nil];
    }
    return _images;
}

@end

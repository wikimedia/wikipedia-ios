//
//  MWKSavedPageEntry.m
//  MediaWikiKit
//
//  Created by Brion on 11/10/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "MediaWikiKit.h"
#import "NSObjectUtilities.h"

typedef NS_ENUM (NSUInteger, MWKSavedPageEntrySchemaVersion) {
    MWKSavedPageEntrySchemaVersionUnknown = 0,
    MWKSavedPageEntrySchemaVersion1       = 1,
    MWKSavedPageEntrySchemaVersionCurrent = MWKSavedPageEntrySchemaVersion1
};

static NSString* const MWKSavedPageEntrySchemaVersionKey = @"schemaVerison";

static NSString* const MWKSavedPageEntryDidMigrateImageDataKey = @"didMigrateImageData";

@interface MWKSavedPageEntry ()

@property (readwrite, strong, nonatomic) MWKTitle* title;

@end
@implementation MWKSavedPageEntry

- (instancetype)initWithTitle:(MWKTitle*)title {
    self = [self initWithSite:title.site];
    if (self) {
        self.title               = title;
        self.didMigrateImageData = YES;
    }
    return self;
}

- (id)initWithDict:(NSDictionary*)dict {
    // Is this safe to run things before init?
    NSString* domain   = [self requiredString:@"domain" dict:dict];
    NSString* language = [self requiredString:@"language" dict:dict];

    self = [self initWithSite:[MWKSite siteWithDomain:domain language:language]];
    if (self) {
        self.title = [self requiredTitle:@"title" dict:dict];
        NSNumber* schemaVersion = dict[MWKSavedPageEntrySchemaVersionKey];
        if (schemaVersion.unsignedIntegerValue == MWKSavedPageEntrySchemaVersion1) {
            self.didMigrateImageData =
                [[self requiredNumber:MWKSavedPageEntryDidMigrateImageDataKey dict:dict] boolValue];
        } else {
            // entries reading legacy data have not been migrated
            self.didMigrateImageData = NO;
        }
    }
    return self;
}

WMF_SYNTHESIZE_IS_EQUAL(MWKSavedPageEntry, isEqualToEntry:)

- (BOOL)isEqualToEntry:(MWKSavedPageEntry*)rhs {
    return WMF_RHS_PROP_EQUAL(title, isEqualToTitle:)
           && self.didMigrateImageData == rhs.didMigrateImageData;
}

- (NSUInteger)hash {
    return self.didMigrateImageData ^ flipBitsWithAdditionalRotation(self.title.hash, 1);
}

#pragma mark - MWKListObject

- (id <NSCopying>)listIndex {
    return self.title;
}

- (id)dataExport {
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];

    dict[MWKSavedPageEntrySchemaVersionKey]       = @(MWKSavedPageEntrySchemaVersionCurrent);
    dict[MWKSavedPageEntryDidMigrateImageDataKey] = @(self.didMigrateImageData);
    dict[@"domain"]                               = self.site.domain;
    dict[@"language"]                             = self.site.language;
    dict[@"title"]                                = self.title.text;

    return [NSDictionary dictionaryWithDictionary:dict];
}

@end

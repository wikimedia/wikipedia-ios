//
//  MWKSavedPageEntry.m
//  MediaWikiKit
//
//  Created by Brion on 11/10/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "MWKSavedPageEntry+ImageMigration.h"
#import "MWKSite.h"
#import "MWKTitle.h"
#import "NSObjectUtilities.h"
#import "NSMutableDictionary+WMFMaybeSet.h"

typedef NS_ENUM (NSUInteger, MWKSavedPageEntrySchemaVersion) {
    MWKSavedPageEntrySchemaVersionUnknown = 0,
    MWKSavedPageEntrySchemaVersion1       = 1,
    MWKSavedPageEntrySchemaVersion2       = 2,
    MWKSavedPageEntrySchemaVersionCurrent = MWKSavedPageEntrySchemaVersion2
};

static NSString* const MWKSavedPageEntrySchemaVersionKey = @"schemaVerison";

static NSString* const MWKSavedPageEntryDidMigrateImageDataKey = @"didMigrateImageData";

@interface MWKSavedPageEntry ()

@property (readwrite, strong, nonatomic) MWKTitle* title;
@property (readwrite, strong, nonatomic) NSDate* date;

@end

@implementation MWKSavedPageEntry

- (instancetype)initWithTitle:(MWKTitle*)title {
    NSParameterAssert(title);
    self = [self initWithSite:title.site];
    if (self) {
        self.title = title;
        self.date  = [NSDate date];
        // defaults to true for instances since new image data will go to the correct location
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

        if (schemaVersion.unsignedIntegerValue > MWKSavedPageEntrySchemaVersion1) {
            self.date = [self requiredDate:@"date" dict:dict];
        } else {
            self.date = [NSDate date];
        }

        if (schemaVersion.unsignedIntegerValue >= MWKSavedPageEntrySchemaVersion1) {
            self.didMigrateImageData =
                [[self requiredNumber:MWKSavedPageEntryDidMigrateImageDataKey dict:dict] boolValue];
        } else {
            // entries reading legacy data have not been migrated
            self.didMigrateImageData = NO;
        }
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    } else if ([object isKindOfClass:[MWKSavedPageEntry class]]) {
        return [self isEqualToEntry:object];
    } else {
        return NO;
    }
}

- (BOOL)isEqualToEntry:(MWKSavedPageEntry*)rhs {
    return WMF_RHS_PROP_EQUAL(title, isEqualToTitle:);
}

- (NSUInteger)hash {
    return self.title.hash;
}

- (NSString*)description {
    return [NSString stringWithFormat:@"%@ %@, didMigrateImageData: %d",
            [super description], self.title, self.didMigrateImageData];
}

#pragma mark - MWKListObject

- (id <NSCopying>)listIndex {
    return self.title;
}

- (id)dataExport {
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];

    [dict wmf_maybeSetObject:@(MWKSavedPageEntrySchemaVersionCurrent) forKey:MWKSavedPageEntrySchemaVersionKey];
    [dict wmf_maybeSetObject:@(self.didMigrateImageData) forKey:MWKSavedPageEntryDidMigrateImageDataKey];
    [dict wmf_maybeSetObject:self.site.domain forKey:@"domain"];
    [dict wmf_maybeSetObject:self.site.language forKey:@"language"];
    [dict wmf_maybeSetObject:self.title.text forKey:@"title"];
    [dict wmf_maybeSetObject:[self iso8601DateString:self.date] forKey:@"date"];
    return [NSDictionary dictionaryWithDictionary:dict];
}

@end

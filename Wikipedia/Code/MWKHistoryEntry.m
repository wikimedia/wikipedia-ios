//
//  MWKHistoryList.m
//  MediaWikiKit
//
//  Created by Brion on 11/3/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "MediaWikiKit.h"
#import "WikipediaAppUtils.h"
#import "NSMutableDictionary+WMFMaybeSet.h"

@interface MWKHistoryEntry ()

@property (readwrite, strong, nonatomic) MWKTitle* title;

@end

@implementation MWKHistoryEntry

- (instancetype)initWithTitle:(MWKTitle*)title {
    NSParameterAssert(title.site.language);
    self = [self initWithSite:title.site];
    if (self) {
        self.title          = title;
        self.date           = [NSDate date];
        self.scrollPosition = 0.0;
    }
    return self;
}

- (instancetype)initWithDict:(NSDictionary*)dict {
    // Is this safe to run things before init?
    NSString* domain   = [self requiredString:@"domain" dict:dict];
    NSString* language = [self requiredString:@"language" dict:dict];

    self = [self initWithSite:[MWKSite siteWithDomain:domain language:language]];
    if (self) {
        self.title                       = [self requiredTitle:@"title" dict:dict allowEmpty:NO];
        self.date                        = [self requiredDate:@"date" dict:dict];
        self.scrollPosition              = [[self requiredNumber:@"scrollPosition" dict:dict] floatValue];
        self.titleWasSignificantlyViewed = [[self optionalNumber:@"titleWasSignificantlyViewed" dict:dict] boolValue];
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    } else if ([object isKindOfClass:[MWKHistoryEntry class]]) {
        return [self isEqualToHistoryEntry:object];
    } else {
        return NO;
    }
}

- (NSUInteger)hash {
    return self.title.hash ^ self.date.hash ^ [@(self.scrollPosition)integerValue];
}

- (BOOL)isEqualToHistoryEntry:(MWKHistoryEntry*)entry {
    return WMF_IS_EQUAL(self.title, entry.title)
           && WMF_EQUAL(self.date, isEqualToDate:, entry.date)
           && self.scrollPosition == entry.scrollPosition;
}

- (NSString*)description {
    return [NSString stringWithFormat:@"%@: {\n"
            "\ttitle: %@,\n"
            "\tdate: %@,\n"
            "\tscrollPosition: %f\n"
            "}",
            [super description],
            self.title.description,
            self.date,
            self.scrollPosition];
}

#pragma mark - MWKListObject

- (id <NSCopying>)listIndex {
    return self.title;
}

- (id)dataExport {
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];

    [dict wmf_maybeSetObject:self.site.domain forKey:@"domain"];
    [dict wmf_maybeSetObject:self.site.language forKey:@"language"];
    [dict wmf_maybeSetObject:self.title.dataBaseKey forKey:@"title"];
    [dict wmf_maybeSetObject:[self iso8601DateString:self.date] forKey:@"date"];
    [dict wmf_maybeSetObject:@(self.scrollPosition) forKey:@"scrollPosition"];
    [dict wmf_maybeSetObject:@(self.titleWasSignificantlyViewed) forKey:@"titleWasSignificantlyViewed"];

    return [NSDictionary dictionaryWithDictionary:dict];
}

@end

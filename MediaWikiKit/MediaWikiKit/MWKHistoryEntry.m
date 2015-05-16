//
//  MWKHistoryList.m
//  MediaWikiKit
//
//  Created by Brion on 11/3/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "MediaWikiKit.h"
#import "WikipediaAppUtils.h"

@interface MWKHistoryEntry ()

@property (readwrite, strong, nonatomic) MWKTitle* title;

@end

@implementation MWKHistoryEntry

- (instancetype)initWithTitle:(MWKTitle*)title discoveryMethod:(MWKHistoryDiscoveryMethod)discoveryMethod {
    self = [self initWithSite:title.site];
    if (self) {
        self.title           = title;
        self.date            = [[NSDate alloc] init];
        self.discoveryMethod = discoveryMethod;
        self.scrollPosition  = 0;
    }
    return self;
}

- (instancetype)initWithDict:(NSDictionary*)dict {
    // Is this safe to run things before init?
    NSString* domain   = [self requiredString:@"domain" dict:dict];
    NSString* language = [self requiredString:@"language" dict:dict];

    self = [self initWithSite:[MWKSite siteWithDomain:domain language:language]];
    if (self) {
        self.title           = [self requiredTitle:@"title" dict:dict];
        self.date            = [self requiredDate:@"date" dict:dict];
        self.discoveryMethod = [MWKHistoryEntry discoveryMethodForString:[self requiredString:@"discoveryMethod" dict:dict]];
        self.scrollPosition  = [[self requiredNumber:@"scrollPosition" dict:dict] intValue];
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
    return self.title.hash ^ self.date.hash ^ self.scrollPosition ^ self.discoveryMethod;
}

- (BOOL)isEqualToHistoryEntry:(MWKHistoryEntry*)entry {
    return WMF_IS_EQUAL(self.title, entry.title)
           && WMF_EQUAL(self.date, isEqualToDate:, entry.date)
           && self.discoveryMethod == entry.discoveryMethod
           && self.scrollPosition == entry.scrollPosition;
}

- (id)dataExport {
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];

    dict[@"domain"]          = self.site.domain;
    dict[@"language"]        = self.site.language;
    dict[@"title"]           = self.title.prefixedDBKey;
    dict[@"date"]            = [self iso8601DateString:self.date];
    dict[@"discoveryMethod"] = [MWKHistoryEntry stringForDiscoveryMethod:self.discoveryMethod];
    dict[@"scrollPosition"]  = @(self.scrollPosition);

    return [NSDictionary dictionaryWithDictionary:dict];
}

+ (NSString*)stringForDiscoveryMethod:(MWKHistoryDiscoveryMethod)discoveryMethod {
    switch (discoveryMethod) {
        case MWKHistoryDiscoveryMethodSearch:
            return @"search";
        case MWKHistoryDiscoveryMethodRandom:
            return @"random";
        case MWKHistoryDiscoveryMethodLink:
            return @"link";
        case MWKHistoryDiscoveryMethodBackForward:
            return @"backforward";
        case MWKHistoryDiscoveryMethodSaved:
            return @"saved";
        default:
            return @"unknown";
    }
}

+ (MWKHistoryDiscoveryMethod)discoveryMethodForString:(NSString*)string {
    if ([string isEqualToString:@"search"]) {
        return MWKHistoryDiscoveryMethodSearch;
    } else if ([string isEqualToString:@"random"]) {
        return MWKHistoryDiscoveryMethodRandom;
    } else if ([string isEqualToString:@"link"]) {
        return MWKHistoryDiscoveryMethodLink;
    } else if ([string isEqualToString:@"backforward"]) {
        return MWKHistoryDiscoveryMethodBackForward;
    } else if ([string isEqualToString:@"saved"]) {
        return MWKHistoryDiscoveryMethodSaved;
    } else {
        return MWKHistoryDiscoveryMethodUnknown;
    }
}

@end

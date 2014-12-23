//
//  MWKHistoryList.m
//  MediaWikiKit
//
//  Created by Brion on 11/3/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "MediaWikiKit.h"

@implementation MWKHistoryEntry

-(instancetype)initWithTitle:(MWKTitle *)title discoveryMethod:(MWKHistoryDiscoveryMethod)discoveryMethod
{
    self = [self initWithSite:title.site];
    if (self) {
        _title = title;
        _date = [[NSDate alloc] init];
        _discoveryMethod = discoveryMethod;
        _scrollPosition = 0;
    }
    return self;
}

-(instancetype)initWithDict:(NSDictionary *)dict
{
    // Is this safe to run things before init?
    NSString *domain = [self requiredString:@"domain" dict:dict];
    NSString *language = [self requiredString:@"language" dict:dict];
    
    self = [self initWithSite:[MWKSite siteWithDomain:domain language:language]];
    if (self) {
        _title = [self requiredTitle:@"title" dict:dict];
        self.date = [self requiredDate:@"date" dict:dict];
        self.discoveryMethod = [MWKHistoryEntry discoveryMethodForString:[self requiredString:@"discoveryMethod" dict:dict]];
        self.scrollPosition = [[self requiredNumber:@"scrollPosition" dict:dict] intValue];
    }
    return self;
}

-(id)dataExport
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    dict[@"domain"] = self.site.domain;
    dict[@"language"] = self.site.language;
    dict[@"title"] = self.title.prefixedDBKey;
    dict[@"date"] = [self iso8601DateString:self.date];
    dict[@"discoveryMethod"] = [MWKHistoryEntry stringForDiscoveryMethod:self.discoveryMethod];
    dict[@"scrollPosition"] = @(self.scrollPosition);
    
    return [NSDictionary dictionaryWithDictionary:dict];
}

+(NSString *)stringForDiscoveryMethod:(MWKHistoryDiscoveryMethod)discoveryMethod
{
    switch (discoveryMethod) {
        case MWK_DISCOVERY_METHOD_SEARCH:
            return @"search";
        case MWK_DISCOVERY_METHOD_RANDOM:
            return @"random";
        case MWK_DISCOVERY_METHOD_LINK:
            return @"link";
        case MWK_DISCOVERY_METHOD_BACKFORWARD:
            return @"backforward";
        default:
            return @"unknown";
    }
}

+(MWKHistoryDiscoveryMethod)discoveryMethodForString:(NSString *)string
{
    if ([string isEqualToString:@"search"]) {
        return MWK_DISCOVERY_METHOD_SEARCH;
    } else if ([string isEqualToString:@"random"]) {
        return MWK_DISCOVERY_METHOD_RANDOM;
    } else if ([string isEqualToString:@"link"]) {
        return MWK_DISCOVERY_METHOD_LINK;
    } else if ([string isEqualToString:@"backforward"]) {
        return MWK_DISCOVERY_METHOD_BACKFORWARD;
    } else {
        return MWK_DISCOVERY_METHOD_UNKNOWN;
    }
}

@end

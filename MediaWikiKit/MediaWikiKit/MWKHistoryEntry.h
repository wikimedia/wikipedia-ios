//
//  MWKHistoryList.h
//  MediaWikiKit
//
//  Created by Brion on 11/3/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "MWKSiteDataObject.h"

@class MWKTitle;

typedef enum {
    MWK_DISCOVERY_METHOD_SEARCH,
    MWK_DISCOVERY_METHOD_RANDOM,
    MWK_DISCOVERY_METHOD_LINK,
    MWK_DISCOVERY_METHOD_BACKFORWARD,
    MWK_DISCOVERY_METHOD_UNKNOWN // reserved
} MWKHistoryDiscoveryMethod;

@interface MWKHistoryEntry : MWKSiteDataObject

@property (readonly) MWKTitle *title;
@property (readwrite) NSDate *date;
@property (readwrite) MWKHistoryDiscoveryMethod discoveryMethod;
@property (readwrite) int scrollPosition;

-(instancetype)initWithTitle:(MWKTitle *)title discoveryMethod:(MWKHistoryDiscoveryMethod)discoveryMethod;
-(instancetype)initWithDict:(NSDictionary *)dict;

+(NSString *)stringForDiscoveryMethod:(MWKHistoryDiscoveryMethod)discoveryMethod;
+(MWKHistoryDiscoveryMethod)discoveryMethodForString:(NSString *)string;

@end

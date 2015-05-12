//
//  MWKHistoryList.h
//  MediaWikiKit
//
//  Created by Brion on 11/3/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "MWKSiteDataObject.h"

@class MWKTitle;

typedef NS_ENUM (NSUInteger, MWKHistoryDiscoveryMethod){
    MWKHistoryDiscoveryMethodSearch,
    MWKHistoryDiscoveryMethodRandom,
    MWKHistoryDiscoveryMethodLink,
    MWKHistoryDiscoveryMethodBackForward,
    MWKHistoryDiscoveryMethodSaved,
    MWKHistoryDiscoveryMethodReload,
    MWKHistoryDiscoveryMethodUnknown
};

@interface MWKHistoryEntry : MWKSiteDataObject

@property (readonly) MWKTitle* title;
@property (readwrite) NSDate* date;
@property (readwrite) MWKHistoryDiscoveryMethod discoveryMethod;
@property (readwrite) int scrollPosition;

- (instancetype)initWithTitle:(MWKTitle*)title discoveryMethod:(MWKHistoryDiscoveryMethod)discoveryMethod;
- (instancetype)initWithDict:(NSDictionary*)dict;

- (BOOL)isEqualToHistoryEntry:(MWKHistoryEntry*)entry;

+ (NSString*)stringForDiscoveryMethod:(MWKHistoryDiscoveryMethod)discoveryMethod;
+ (MWKHistoryDiscoveryMethod)discoveryMethodForString:(NSString*)string;

@end

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

@property (readonly, strong, nonatomic) MWKTitle* title;
@property (readwrite, strong, nonatomic) NSDate* date;
@property (readwrite, assign, nonatomic) MWKHistoryDiscoveryMethod discoveryMethod;
@property (readwrite, assign, nonatomic) int scrollPosition;

- (instancetype)initWithTitle:(MWKTitle*)title discoveryMethod:(MWKHistoryDiscoveryMethod)discoveryMethod;
- (instancetype)initWithDict:(NSDictionary*)dict;

- (BOOL)isEqualToHistoryEntry:(MWKHistoryEntry*)entry;

+ (NSString*)stringForDiscoveryMethod:(MWKHistoryDiscoveryMethod)discoveryMethod;
+ (MWKHistoryDiscoveryMethod)discoveryMethodForString:(NSString*)string;

@end

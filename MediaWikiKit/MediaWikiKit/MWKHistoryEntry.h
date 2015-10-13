//
//  MWKHistoryList.h
//  MediaWikiKit
//
//  Created by Brion on 11/3/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "MWKSiteDataObject.h"
#import "MWKList.h"

@class MWKTitle;

typedef NS_ENUM (NSUInteger, MWKHistoryDiscoveryMethod){
    MWKHistoryDiscoveryMethodUnknown,
    MWKHistoryDiscoveryMethodSearch,
    MWKHistoryDiscoveryMethodRandom,
    MWKHistoryDiscoveryMethodLink,
    MWKHistoryDiscoveryMethodBackForward,
    MWKHistoryDiscoveryMethodSaved,
    MWKHistoryDiscoveryMethodReloadFromNetwork,
    MWKHistoryDiscoveryMethodReloadFromCache,
};

@interface MWKHistoryEntry : MWKSiteDataObject
    <MWKListObject>

@property (readonly, strong, nonatomic) MWKTitle* title;
@property (readwrite, strong, nonatomic) NSDate* date;
@property (readwrite, assign, nonatomic) MWKHistoryDiscoveryMethod discoveryMethod;
@property (readwrite, assign, nonatomic) CGFloat scrollPosition;

- (instancetype)initWithTitle:(MWKTitle*)title discoveryMethod:(MWKHistoryDiscoveryMethod)discoveryMethod;
- (instancetype)initWithDict:(NSDictionary*)dict;

- (BOOL)isEqualToHistoryEntry:(MWKHistoryEntry*)entry;

+ (NSString*)stringForDiscoveryMethod:(MWKHistoryDiscoveryMethod)discoveryMethod;
+ (MWKHistoryDiscoveryMethod)discoveryMethodForString:(NSString*)string;

- (BOOL)discoveryMethodRequiresScrollPositionRestore;

@end

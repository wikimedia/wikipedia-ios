//
//  MWKSiteInfo.h
//  Wikipedia
//
//  Created by Brian Gerstle on 5/29/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKDataObject.h"

@class MWKTitle, MWKSite;

NS_ASSUME_NONNULL_BEGIN

/// Type for siteinfo API responses.
/// @see https://www.mediawiki.org/wiki/API:Siteinfo
@interface MWKSiteInfo : NSObject

/// Site described by the receiver.
@property (readonly, copy, nonatomic) MWKSite* site;

/// Raw title for the receiver's main page.
@property (readonly, copy, nonatomic) NSString* mainPageTitleText;

- (instancetype)initWithSite:(MWKSite*)site
           mainPageTitleText:(NSString*)mainPage NS_DESIGNATED_INITIALIZER;

- (BOOL)isEqualToSiteInfo:(MWKSiteInfo*)siteInfo;

///
/// @name Computed Properties
///

/// @return Parsed @c MWKTitle from @c mainPage.
- (MWKTitle*)mainPageTitle;

@end

NS_ASSUME_NONNULL_END

//
//  WMFMostReadListDataSource.h
//  Wikipedia
//
//  Created by Brian Gerstle on 2/16/16.
//  Copyright © 2016 Wikimedia Foundation. All rights reserved.
//

#import <SSDataSources/SSDataSources.h>
#import "WMFTitleListDataSource.h"

@class MWKSearchResult;

@interface WMFMostReadListDataSource : SSArrayDataSource
    <WMFTitleListDataSource>

- (instancetype)initWithItems:(NSArray*)items NS_UNAVAILABLE;

- (instancetype)initWithPreviews:(NSArray<MWKSearchResult*>*)previews fromSite:(MWKSite*)site;

@end

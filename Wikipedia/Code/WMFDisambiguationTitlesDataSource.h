//  Created by Monte Hurd on 12/16/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.

#import <Foundation/Foundation.h>
#import <SSDataSources/SSArrayDataSource.h>
#import "WMFTitleListDataSource.h"

NS_ASSUME_NONNULL_BEGIN

@class WMFTitlesSearchResults;
@class WMFTitlesSearchFetcher;
@class MWKSavedPageList;
@class MWKTitle;

@interface WMFDisambiguationTitlesDataSource : SSArrayDataSource
    <WMFTitleListDataSource>

@property (nonatomic, strong, readonly, nullable) WMFTitlesSearchResults* titlesSearchResults;

- (instancetype)initWithTitles:(NSArray<MWKTitle*>*)titles
                          site:(MWKSite*)site
                       fetcher:(WMFTitlesSearchFetcher*)fetcher NS_DESIGNATED_INITIALIZER;

- (AnyPromise*)fetch;

@end

NS_ASSUME_NONNULL_END

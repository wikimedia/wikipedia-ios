//  Created by Monte Hurd on 12/16/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.

#import <Foundation/Foundation.h>
#import <SSDataSources/SSArrayDataSource.h>
#import "WMFTitleListDataSource.h"

NS_ASSUME_NONNULL_BEGIN

@class MWKSearchResult;
@class WMFArticlePreviewFetcher;
@class MWKSavedPageList;
@class MWKTitle;

@interface WMFArticlePreviewDataSource : SSArrayDataSource
    <WMFTitleListDataSource>

@property (nonatomic, strong, readonly, nullable) NSArray<MWKSearchResult*>* previewResults;

- (instancetype)initWithTitles:(NSArray<MWKTitle*>*)titles
                          site:(MWKSite*)site
                       fetcher:(WMFArticlePreviewFetcher*)fetcher NS_DESIGNATED_INITIALIZER;

- (void)fetch;

@end

NS_ASSUME_NONNULL_END

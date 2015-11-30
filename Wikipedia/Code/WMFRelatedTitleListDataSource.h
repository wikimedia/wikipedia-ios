//
//  WMFRelatedTitleListDataSource.h
//  Wikipedia
//
//  Created by Brian Gerstle on 9/4/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SSDataSources/SSArrayDataSource.h>
#import "WMFTitleListDataSource.h"

NS_ASSUME_NONNULL_BEGIN

@class WMFRelatedSearchResults;
@class WMFRelatedSearchFetcher;
@class MWKSavedPageList;
@class MWKDataStore;
@class MWKTitle;

@interface WMFRelatedTitleListDataSource : SSArrayDataSource
    <WMFTitleListDataSource>

@property (nonatomic, strong, readonly, nullable) WMFRelatedSearchResults* relatedSearchResults;

- (instancetype)initWithTitle:(MWKTitle*)title
                    dataStore:(MWKDataStore*)dataStore
                savedPageList:(MWKSavedPageList*)savedPageList
                  resultLimit:(NSUInteger)resultLimit;

- (instancetype)initWithTitle:(MWKTitle*)title
                    dataStore:(MWKDataStore*)dataStore
                savedPageList:(MWKSavedPageList*)savedPageList
                  resultLimit:(NSUInteger)resultLimit
                      fetcher:(WMFRelatedSearchFetcher*)fetcher NS_DESIGNATED_INITIALIZER;

- (AnyPromise*)fetch;

@end

NS_ASSUME_NONNULL_END

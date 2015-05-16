//
//  MWKUserDataStore.h
//  MediaWikiKit
//
//  Created by Brion on 11/18/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MWKHistoryEntry.h"

@class MWKTitle;
@class MWKDataStore;
@class MWKHistoryList;
@class MWKSavedPageList;
@class MWKRecentSearchList;

@interface MWKUserDataStore : NSObject

@property (readonly, weak, nonatomic) MWKDataStore* dataStore;
@property (readonly, strong, nonatomic) MWKHistoryList* historyList;
@property (readonly, strong, nonatomic) MWKSavedPageList* savedPageList;
@property (readonly, strong, nonatomic) MWKRecentSearchList* recentSearchList;

- (instancetype)initWithDataStore:(MWKDataStore*)dataStore;

- (BOOL)save:(NSError**)error;
- (void)save;

- (void)reset;

- (void)updateHistory:(MWKTitle*)title discoveryMethod:(MWKHistoryDiscoveryMethod)discoveryMethod;
- (void)savePage:(MWKTitle*)title;
- (void)unsavePage:(MWKTitle*)title;


@end

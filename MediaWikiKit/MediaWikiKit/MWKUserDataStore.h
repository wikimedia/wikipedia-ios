//
//  MWKUserDataStore.h
//  MediaWikiKit
//
//  Created by Brion on 11/18/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MWKDataStore;
@class MWKHistoryList;
@class MWKSavedPageList;
@class MWKRecentSearchList;

@interface MWKUserDataStore : NSObject

@property (readonly) MWKDataStore *dataStore;
@property (readonly) MWKHistoryList *historyList;
@property (readonly) MWKSavedPageList *savedPageList;
@property (readonly) MWKRecentSearchList *recentSearchList;

-(instancetype)initWithDataStore:(MWKDataStore *)dataStore;

-(void)save;

-(void)updateHistory:(MWKTitle *)title discoveryMethod:(MWKHistoryDiscoveryMethod)discoveryMethod;
-(void)savePage:(MWKTitle *)title;
-(void)unsavePage:(MWKTitle *)title;

@end

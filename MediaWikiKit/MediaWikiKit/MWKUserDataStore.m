//
//  MWKUserDataStore.m
//  MediaWikiKit
//
//  Created by Brion on 11/18/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "MediaWikiKit.h"

@implementation MWKUserDataStore {
    MWKHistoryList *_historyList;
    MWKSavedPageList *_savedPageList;
    MWKRecentSearchList *_recentSearchList;
}

-(void)save
{
    if (_historyList && _historyList.dirty) {
        [self.dataStore saveHistoryList:_historyList];
    }
    if (_savedPageList && _savedPageList.dirty) {
        [self.dataStore saveSavedPageList:_savedPageList];
    }
    if (_recentSearchList && _recentSearchList.dirty) {
        [self.dataStore saveRecentSearchList:_recentSearchList];
    }
}

-(instancetype)initWithDataStore:(MWKDataStore *)dataStore
{
    self = [self init];
    if (self) {
        _dataStore = dataStore;
        
        // Load these on demand
        _historyList = nil;
        _savedPageList = nil;
        _recentSearchList = nil;
    }
    return self;
}

-(MWKHistoryList *)historyList
{
    if (_historyList == nil) {
        _historyList = [self.dataStore historyList];
    }
    return _historyList;
}

-(MWKSavedPageList *)savedPageList
{
    if (_savedPageList == nil) {
        _savedPageList = [self.dataStore savedPageList];
    }
    return _savedPageList;
}

-(MWKRecentSearchList *)recentSearchList
{
    if (_recentSearchList) {
        _recentSearchList = [self.dataStore recentSearchList];
    }
    return _recentSearchList;
}

-(void)updateHistory:(MWKTitle *)title discoveryMethod:(MWKHistoryDiscoveryMethod)discoveryMethod
{
    MWKHistoryEntry *entry = [[MWKHistoryEntry alloc] initWithTitle:title discoveryMethod:discoveryMethod];
    [self.historyList addEntry:entry];
    [self save];
}

-(void)savePage:(MWKTitle *)title
{
    MWKSavedPageEntry *entry = [[MWKSavedPageEntry alloc] initWithTitle:title];
    [self.savedPageList addEntry:entry];
    [self save];
}

-(void)unsavePage:(MWKTitle *)title
{
    MWKSavedPageEntry *entry = [self.savedPageList entryForTitle:title];
    if (entry) {
        [self.savedPageList removeEntry:entry];
        [self save];
    }
}


@end

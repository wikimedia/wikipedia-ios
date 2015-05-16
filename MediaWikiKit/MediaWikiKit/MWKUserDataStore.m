//
//  MWKUserDataStore.m
//  MediaWikiKit
//
//  Created by Brion on 11/18/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "MediaWikiKit.h"

@interface MWKUserDataStore ()

@property (readwrite, weak, nonatomic) MWKDataStore* dataStore;
@property (readwrite, strong, nonatomic) MWKHistoryList* historyList;
@property (readwrite, strong, nonatomic) MWKSavedPageList* savedPageList;
@property (readwrite, strong, nonatomic) MWKRecentSearchList* recentSearchList;

@end

@implementation MWKUserDataStore

- (BOOL)save:(NSError**)error {
    BOOL success = YES;

    if (_historyList && _historyList.dirty) {
        if (![self.dataStore saveHistoryList:_historyList error:error]) {
            NSAssert(NO, @"Error saving history: %@", [*error localizedDescription]);
        }
        ;
    }
    if (_savedPageList && _savedPageList.dirty) {
        [self.dataStore saveSavedPageList:_savedPageList];
    }
    if (_recentSearchList && _recentSearchList.dirty) {
        [self.dataStore saveRecentSearchList:_recentSearchList];
    }

    return success;
}

- (void)save {
    [self save:NULL];
}

/// Clear out any currently loaded data and force it to be reloaded on next use
- (void)reset {
    self.historyList      = nil;
    self.savedPageList    = nil;
    self.recentSearchList = nil;
}

- (instancetype)initWithDataStore:(MWKDataStore*)dataStore {
    self = [self init];
    if (self) {
        self.dataStore = dataStore;
    }
    return self;
}

- (MWKHistoryList*)historyList {
    if (_historyList == nil) {
        _historyList = [self.dataStore historyList];
        if (_historyList == nil) {
            _historyList = [[MWKHistoryList alloc] init];
        }
    }
    return _historyList;
}

- (MWKSavedPageList*)savedPageList {
    if (_savedPageList == nil) {
        _savedPageList = [self.dataStore savedPageList];
        if (_savedPageList == nil) {
            _savedPageList = [[MWKSavedPageList alloc] init];
        }
    }
    return _savedPageList;
}

- (MWKRecentSearchList*)recentSearchList {
    if (_recentSearchList) {
        _recentSearchList = [self.dataStore recentSearchList];
        if (_recentSearchList == nil) {
            _recentSearchList = [[MWKRecentSearchList alloc] init];
        }
    }
    return _recentSearchList;
}

- (void)updateHistory:(MWKTitle*)title discoveryMethod:(MWKHistoryDiscoveryMethod)discoveryMethod {
    if (title == nil) {
        @throw [NSException exceptionWithName:@"MWKUserDataStoreException"
                                       reason:@"updateHistory called with null title" userInfo:@{}];
    }
    MWKHistoryEntry* entry = [self.historyList entryForTitle:title];
    if (entry) {
        entry.discoveryMethod = discoveryMethod;
        entry.date            = [NSDate date];
        // Retain saved scroll position
    } else {
        entry = [[MWKHistoryEntry alloc] initWithTitle:title discoveryMethod:discoveryMethod];
    }
    [self.historyList addEntry:entry];
    [self save];
}

- (void)savePage:(MWKTitle*)title {
    MWKSavedPageEntry* entry = [[MWKSavedPageEntry alloc] initWithTitle:title];
    [self.savedPageList addEntry:entry];
    [self save];
}

- (void)unsavePage:(MWKTitle*)title {
    MWKSavedPageEntry* entry = [self.savedPageList entryForTitle:title];
    if (entry) {
        [self.savedPageList removeEntry:entry];
        [self save];
    }
}

@end

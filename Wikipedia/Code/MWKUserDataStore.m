#import "MWKUserDataStore.h"
#import "MWKDataStore.h"
#import "MWKHistoryList.h"
#import "MWKSavedPageList.h"
#import "MWKRecentSearchList.h"
#import "WMFRelatedSectionBlackList.h"
#import "Wikipedia-Swift.h"
#import <YapDataBase/YapDatabase.h>


@interface MWKUserDataStore ()

@property (readwrite, weak, nonatomic) MWKDataStore* dataStore;
@property (readwrite, strong, nonatomic) MWKHistoryList* historyList;
@property (readwrite, strong, nonatomic) MWKSavedPageList* savedPageList;
@property (readwrite, strong, nonatomic) MWKRecentSearchList* recentSearchList;
@property (readwrite, strong, nonatomic) WMFRelatedSectionBlackList* blackList;

@end

@implementation MWKUserDataStore

- (instancetype)initWithDataStore:(MWKDataStore*)dataStore {
    self = [self init];
    if (self) {
        self.dataStore = dataStore;
    }
    return self;
}

- (MWKHistoryList*)historyList {
    if (!_historyList) {
        _historyList = [[MWKHistoryList alloc] initWithDataStore:self.dataStore];
    }
    return _historyList;
}

- (MWKSavedPageList*)savedPageList {
    if (!_savedPageList) {
        _savedPageList = [[MWKSavedPageList alloc] initWithDataStore:self.dataStore];
    }
    return _savedPageList;
}

- (MWKRecentSearchList*)recentSearchList {
    if (!_recentSearchList) {
        _recentSearchList = [[MWKRecentSearchList alloc] initWithDataStore:self.dataStore];
    }
    return _recentSearchList;
}

- (WMFRelatedSectionBlackList*)blackList {
    if (!_blackList) {
        _blackList = [[WMFRelatedSectionBlackList alloc] initWithDataStore:self.dataStore];
    }
    return _blackList;
}

- (AnyPromise*)reset {
    self.historyList      = nil;
    self.savedPageList    = nil;
    self.recentSearchList = nil;
    self.blackList        = nil;
    return [AnyPromise promiseWithValue:nil];
}

@end

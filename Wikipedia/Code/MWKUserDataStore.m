#import "MediaWikiKit.h"
#import "Wikipedia-Swift.h"

@interface MWKUserDataStore ()

@property(readwrite, weak, nonatomic) MWKDataStore *dataStore;
@property(readwrite, strong, nonatomic) MWKHistoryList *historyList;
@property(readwrite, strong, nonatomic) MWKSavedPageList *savedPageList;
@property(readwrite, strong, nonatomic) MWKRecentSearchList *recentSearchList;

@end

@implementation MWKUserDataStore

- (instancetype)initWithDataStore:(MWKDataStore *)dataStore {
  self = [self init];
  if (self) {
    self.dataStore = dataStore;
  }
  return self;
}

- (MWKHistoryList *)historyList {
  if (!_historyList) {
    _historyList = [[MWKHistoryList alloc] initWithDataStore:self.dataStore];
  }
  return _historyList;
}

- (MWKSavedPageList *)savedPageList {
  if (!_savedPageList) {
    _savedPageList = [[MWKSavedPageList alloc] initWithDataStore:self.dataStore];
  }
  return _savedPageList;
}

- (MWKRecentSearchList *)recentSearchList {
  if (!_recentSearchList) {
    _recentSearchList = [[MWKRecentSearchList alloc] initWithDataStore:self.dataStore];
  }
  return _recentSearchList;
}

- (AnyPromise *)save {
  return [self.historyList save].then([self.savedPageList save]).then([self.recentSearchList save]);
}

- (AnyPromise *)reset {
  self.historyList = nil;
  self.savedPageList = nil;
  self.recentSearchList = nil;

  return [AnyPromise promiseWithValue:nil];
}

@end

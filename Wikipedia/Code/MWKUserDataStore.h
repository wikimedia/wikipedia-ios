#import <Foundation/Foundation.h>

#import "MWKHistoryEntry.h"

@class MWKDataStore;
@class MWKHistoryList;
@class MWKSavedPageList;
@class MWKRecentSearchList;

@interface MWKUserDataStore : NSObject

@property(readonly, weak, nonatomic) MWKDataStore *dataStore;
@property(readonly, strong, nonatomic) MWKHistoryList *historyList;
@property(readonly, strong, nonatomic) MWKSavedPageList *savedPageList;
@property(readonly, strong, nonatomic) MWKRecentSearchList *recentSearchList;

- (instancetype)initWithDataStore:(MWKDataStore *)dataStore;

/**
 *  Save changes to any of the lists managed by the user data store.
 *  You do NOT need to call this if you are performing any of the tasks above.
 *  Only call this if you are modifying entries or lists directly.
 *
 *  @return The task. The result will be nil.
 */
- (AnyPromise *)save;

/**
 *  Clear out any cached list and force them to be reloaded on demand.
 *
 *  @return The task. The result will be nil.
 */
- (AnyPromise *)reset;

@end

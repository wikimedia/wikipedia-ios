
#import <Foundation/Foundation.h>

#import "MWKHistoryEntry.h"

@class MWKDataStore;
@class MWKHistoryList;
@class MWKSavedPageList;
@class MWKRecentSearchList;
@class WMFRelatedSectionBlackList;

@interface MWKUserDataStore : NSObject

@property (readonly, weak, nonatomic) MWKDataStore* dataStore;
@property (readonly, strong, nonatomic) MWKHistoryList* historyList;
@property (readonly, strong, nonatomic) MWKSavedPageList* savedPageList;
@property (readonly, strong, nonatomic) MWKRecentSearchList* recentSearchList;
@property (readonly, strong, nonatomic) WMFRelatedSectionBlackList* blackList;

- (instancetype)initWithDataStore:(MWKDataStore*)dataStore;

/**
 *  Clear out any cached list and force them to be reloaded on demand.
 *
 *  @return The task. The result will be nil.
 */
- (AnyPromise*)reset;

@end

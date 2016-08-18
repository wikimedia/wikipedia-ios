#import "MWKListTestBase.h"

@class MWKDataStore;

/**
 *  Shared tests for persisting @c MWKList subclasses which conform to @c MWKDataStoreList
 */
@interface MWKDataStoreListTests : MWKListTestBase

/// Temporary data store which is setup & torn down between tests.
@property (nonatomic, strong) MWKDataStore *tempDataStore;

/**
 *  Assert equality of two lists.
 *
 *  Default implementation checks `isEqual:` of both lists' entries. Override this method to
 *  add additional verification, but call @c super if you need `isEqual:` checked as well.
 *
 *  @param list      A list which was exercised by a test.
 *  @param otherList The same list read from disk after the test.
 */
- (void)verifyList:(MWKList *)list isEqualToList:(MWKList *)otherList;

@end

@import XCTest;

#import "MWKList+Subclass.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Base class for verifying universal behaviors which should hold for an @c MWKList or subclass.
 */
@interface MWKListTestBase : XCTestCase

/// An array of test objects created in @c setUp.
@property (nonatomic, strong, nullable) NSArray *testObjects;

/**
 *  @return A unique entry object for use with the receiver's @c listClass.
 */
+ (id)uniqueListEntry;

/**
 *  The @c MWKList subclass to exercise in the receiver's tests.
 *
 *  @return A class which is @c MWKList or one of its specialized subclasses.
 */
+ (Class)listClass;

/**
 *  Create a list with the given entries.
 *
 *  Override this method if your @c MWKList subclass has other initializer parameters.
 *
 *  @param entries The entries to pass to @c initWithEntries:
 *
 *  @return A new @c MWKList (or subclass) initialized with the given entries.
 */
- (MWKList *)listWithEntries:(nullable NSArray *)entries;

@end

/**
 *  Dummy entry class used when testing a generic @c MWKList.
 */
@interface MWKListDummyEntry : NSObject <MWKListObject>

@property (nonatomic, strong) NSString *listIndex;

@end

NS_ASSUME_NONNULL_END

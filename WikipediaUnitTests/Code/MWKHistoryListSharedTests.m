#import "MWKListSharedTests.h"
#import "MWKHistoryEntry+MWKRandom.h"

@interface MWKHistoryListSharedTests : MWKListSharedTests

@end

@implementation MWKHistoryListSharedTests

#pragma mark - MWKListTestBase

+ (id)uniqueListEntry {
    return [MWKHistoryEntry random];
}

+ (Class)listClass {
    return [MWKHistoryList class];
}

@end

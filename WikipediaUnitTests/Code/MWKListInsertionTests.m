#import "MWKListInsertionTests.h"

#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

#import "HCIsCollectionContainingInAnyOrder+WMFCollectionMatcherUtils.h"

@implementation MWKListInsertionTests

- (void)testInsert {
    MWKList *list = [self listWithEntries:nil];
    [list addEntry:self.testObjects[0]];
    [list addEntry:self.testObjects[1]];
    [list addEntry:self.testObjects[2]];
    [list addEntry:self.testObjects[3]];
    [list insertEntry:self.testObjects[4] atIndex:2];
    assertThat([list entries], is(equalTo(@[
                   self.testObjects[0],
                   self.testObjects[1],
                   self.testObjects[4], //< inserted
                   self.testObjects[2],
                   self.testObjects[3]
               ])));
}

@end

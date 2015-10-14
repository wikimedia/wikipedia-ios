//
//  MWKListSharedTests.m
//  Wikipedia
//
//  Created by Brian Gerstle on 10/14/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKListSharedTests.h"

#define HC_SHORTHAND 1
#import <OCHamcrest/OCHamcrest.h>

#import "HCIsCollectionContainingInAnyOrder+WMFCollectionMatcherUtils.h"

@implementation MWKListSharedTests

- (void)testEmptyWhenInitializedWithNilEntries {
    MWKList* list = [self listWithEntries:nil];
    assertThat(list.entries, isEmpty());
    assertThat(@([list countOfEntries]), is(@0));
    assertThat(@(list.dirty), isFalse());
}

- (void)testContainsAllUniqueEntriesPassedToInit {
    MWKList* list = [self listWithEntries:self.testObjects];
    assertThat(list.entries, hasCountOf(self.testObjects.count));
    assertThat(list.entries, containsItemsInCollectionInAnyOrder(self.testObjects));
    assertThat(@(list.dirty), isFalse());
}

- (void)testContainsAddedEntry {
    MWKList* list = [self listWithEntries:nil];
    id<MWKListObject> firstEntry = [self.testObjects firstObject];
    [list addEntry:firstEntry];
    assertThat([list entryAtIndex:0], is(firstEntry));
    assertThat([list entryForListIndex:[firstEntry listIndex]], is(firstEntry));
    assertThat(@([list containsEntryForListIndex:[firstEntry listIndex]]), isTrue());
    assertThat(@(list.dirty), isTrue());
}

- (void)testContainsInsertedEntry {
    MWKList* list = [self listWithEntries:nil];
    id<MWKListObject> firstEntry = [self.testObjects firstObject];
    [list insertEntry:firstEntry atIndex:0];
    assertThat([list entryAtIndex:0], is(firstEntry));
    assertThat([list entryForListIndex:[firstEntry listIndex]], is(firstEntry));
    assertThat(@([list containsEntryForListIndex:[firstEntry listIndex]]), isTrue());
    assertThat(@(list.dirty), isTrue());
}

- (void)testDoesNotContainRemovedEntries {
    MWKList* list = [self listWithEntries:self.testObjects];
    id<MWKListObject> firstEntry = [self.testObjects firstObject];
    [list removeEntryWithListIndex:[firstEntry listIndex]];
    assertThat(@([list containsEntryForListIndex:[firstEntry listIndex]]), isFalse());
    assertThat([list entryForListIndex:[firstEntry listIndex]], is(nilValue()));
    assertThat(@(list.dirty), isTrue());
}

- (void)testIsEmptyAfterRemovingAllEntries {
    MWKList* list = [self listWithEntries:self.testObjects];
    [list removeAllEntries];
    assertThat(list.entries, isEmpty());
    assertThat(@(list.countOfEntries), is(@0));
    assertThat(@(list.dirty), isTrue());
}

@end

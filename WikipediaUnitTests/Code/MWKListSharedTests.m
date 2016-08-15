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

#pragma mark - Lifecycle

- (void)testEmptyWhenInitializedWithNilEntries {
    MWKList *list = [self listWithEntries:nil];
    assertThat(list.entries, isEmpty());
    assertThat(@([list countOfEntries]), is(@0));
    assertThat(@(list.dirty), isFalse());
}

- (void)testContainsAllUniqueEntriesPassedToInit {
    MWKList *list = [self listWithEntries:self.testObjects];
    assertThat(list.entries, hasCountOf(self.testObjects.count));
    assertThat(list.entries, containsItemsInCollectionInAnyOrder(self.testObjects));
    assertThat(@(list.dirty), isFalse());
}

#pragma mark - Mutation

- (void)testContainsAddedEntry {
    MWKList *list = [self listWithEntries:nil];
    id<MWKListObject> firstEntry = [self.testObjects firstObject];
    [list addEntry:firstEntry];
    assertThat([list entryAtIndex:0], is(firstEntry));
    assertThat([list entryForListIndex:[firstEntry listIndex]], is(firstEntry));
    assertThat(@([list containsEntryForListIndex:[firstEntry listIndex]]), isTrue());
    assertThat(@(list.dirty), isTrue());
}

- (void)testDoesNotContainRemovedEntries {
    MWKList *list = [self listWithEntries:self.testObjects];
    id<MWKListObject> firstEntry = [self.testObjects firstObject];
    [list removeEntryWithListIndex:[firstEntry listIndex]];
    assertThat(@([list containsEntryForListIndex:[firstEntry listIndex]]), isFalse());
    assertThat([list entryForListIndex:[firstEntry listIndex]], is(nilValue()));
    assertThat(@(list.dirty), isTrue());
}

- (void)testIsEmptyAfterRemovingAllEntries {
    MWKList *list = [self listWithEntries:self.testObjects];
    [list removeAllEntries];
    assertThat(list.entries, isEmpty());
    assertThat(@(list.countOfEntries), is(@0));
    assertThat(@(list.dirty), isTrue());
}

- (void)testContainsAllUniqueAddedEntries {
    MWKList *list = [self listWithEntries:nil];
    [list addEntry:self.testObjects[0]];
    [list addEntry:self.testObjects[1]];
    [list addEntry:self.testObjects[2]];
    [list addEntry:self.testObjects[3]];
    assertThat(list.entries, containsItemsInCollectionInAnyOrder([self.testObjects subarrayWithRange:NSMakeRange(0, 4)]));
}

- (void)testAddThenRemove {
    MWKList *list = [self listWithEntries:nil];
    [list addEntry:self.testObjects[0]];
    [list removeEntry:self.testObjects[0]];
    assertThat(list.entries, isEmpty());
    assertThat(@(list.dirty), isTrue());
}

- (void)testAddThenRemoveByListIndex {
    MWKList *list = [self listWithEntries:nil];
    [list addEntry:self.testObjects[0]];
    [list removeEntryWithListIndex:[self.testObjects[0] listIndex]];
    assertThat(list.entries, isEmpty());
    assertThat(@(list.dirty), isTrue());
}

- (void)testKVO {
    MWKList *list = [self listWithEntries:nil];
    NSMutableArray *observations = [NSMutableArray new];

    [self.KVOController observe:list
                        keyPath:WMF_SAFE_KEYPATH(list, entries)
                        options:0
                          block:^(id observer, id object, NSDictionary *change) {
                            [observations addObject:change];
                          }];

    [list addEntry:self.testObjects[0]];
    [list removeEntry:self.testObjects[0]];

    assertThat(observations, hasCountOf(2));

    NSDictionary *firstChangeDictionary = observations[0];
    assertThat(firstChangeDictionary[NSKeyValueChangeKindKey], is(@(NSKeyValueChangeInsertion)));
    assertThat(firstChangeDictionary[NSKeyValueChangeIndexesKey], is(equalTo([NSIndexSet indexSetWithIndex:0])));

    NSDictionary *secondChangeDictionary = observations[1];
    assertThat(secondChangeDictionary[NSKeyValueChangeKindKey], is(@(NSKeyValueChangeRemoval)));
    assertThat(secondChangeDictionary[NSKeyValueChangeIndexesKey], is(equalTo([NSIndexSet indexSetWithIndex:0])));

    [self.KVOController unobserve:list];
}

@end

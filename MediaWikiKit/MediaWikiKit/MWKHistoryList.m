//
//  MWKHistoryList.m
//  MediaWikiKit
//
//  Created by Brion on 11/17/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "MediaWikiKit.h"

@interface MWKHistoryList ()

@property (nonatomic, readwrite, assign) NSUInteger length;
@property (nonatomic, readwrite, strong) MWKHistoryEntry* mostRecentEntry;
@property (nonatomic, strong)  NSMutableArray* entries;
@property (nonatomic, strong) NSMutableDictionary* entriesByTitle;

@end

@implementation MWKHistoryList

- (NSUInteger)length {
    return [self.entries count];
}

- (MWKHistoryEntry*)mostRecentEntry {
    return [self.entries firstObject];
}

- (MWKHistoryEntry*)entryAtIndex:(NSUInteger)index {
    return self.entries[index];
}

- (MWKHistoryEntry*)entryForTitle:(MWKTitle*)title {
    return self.entriesByTitle[title];
}

- (NSUInteger)indexForEntry:(MWKHistoryEntry*)entry {
    return [self.entries indexOfObject:entry];
}

- (MWKHistoryEntry*)entryAfterEntry:(MWKHistoryEntry*)entry {
    NSUInteger index = [self indexForEntry:entry];
    if (index == NSNotFound) {
        return nil;
    } else if (index > 0) {
        return [self entryAtIndex:index - 1];
    } else {
        return nil;
    }
}

- (MWKHistoryEntry*)entryBeforeEntry:(MWKHistoryEntry*)entry {
    NSUInteger index = [self indexForEntry:entry];
    if (index == NSNotFound) {
        return nil;
    } else if (index + 1 < self.length) {
        return [self entryAtIndex:index + 1];
    } else {
        return nil;
    }
}

#pragma mark - update methods

- (void)addEntry:(MWKHistoryEntry*)entry {
    if (entry.title == nil) {
        return;
    }
    MWKHistoryEntry* oldEntry = [self entryForTitle:entry.title];
    if (oldEntry) {
        // Replace the old entry and move to top
        [self.entries removeObject:oldEntry];
    }
    [self.entries insertObject:entry atIndex:0];
    self.entriesByTitle[entry.title] = entry;
    self.dirty                       = YES;
}

- (void)removeEntry:(MWKHistoryEntry*)entry {
    if (entry.title == nil) {
        return;
    }
    [self.entries removeObject:entry];
    [self.entriesByTitle removeObjectForKey:entry.title];
    self.dirty = YES;
}

- (void)removeAllEntries;
{
    [self.entries removeAllObjects];
    [self.entriesByTitle removeAllObjects];
    self.dirty = YES;
}

#pragma mark - data i/o methods

- (instancetype)init {
    self = [super init];
    if (self) {
        self.entries        = [[NSMutableArray alloc] init];
        self.entriesByTitle = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (instancetype)initWithDict:(NSDictionary*)dict {
    self = [self init];
    if (self) {
        NSArray* arr = dict[@"entries"];
        if (arr) {
            self.entries = [[NSMutableArray alloc] init];
            for (NSDictionary* entryDict in arr) {
                MWKHistoryEntry* entry = [[MWKHistoryEntry alloc] initWithDict:entryDict];
                [self.entries addObject:entry];
                self.entriesByTitle[entry.title] = entry;
            }
        }
        self.dirty = NO;
    }
    return self;
}

- (id)dataExport {
    NSMutableArray* array = [[NSMutableArray alloc] init];

    for (MWKHistoryEntry* entry in self.entries) {
        [array addObject:[entry dataExport]];
    }

    self.dirty = NO;
    return @{@"entries": [NSArray arrayWithArray:array]};
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState*)state
                                  objects:(__unsafe_unretained id [])stackbuf
                                    count:(NSUInteger)len {
    return [self.entries countByEnumeratingWithState:state objects:stackbuf count:len];
}

@end

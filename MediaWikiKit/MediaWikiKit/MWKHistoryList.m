//
//  MWKHistoryList.m
//  MediaWikiKit
//
//  Created by Brion on 11/17/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "MediaWikiKit.h"

@implementation MWKHistoryList {
    NSMutableArray *entries;
    NSMutableDictionary *entriesByTitle;
}

-(NSUInteger)length
{
    return [entries count];
}

-(MWKHistoryEntry *)entryAtIndex:(NSUInteger)index
{
    return entries[index];
}

-(MWKHistoryEntry *)entryForTitle:(MWKTitle *)title
{
    return entriesByTitle[title];
}

-(NSUInteger)indexForEntry:(MWKHistoryEntry *)entry
{
    return [entries indexOfObject:entry];
}

-(MWKHistoryEntry *)entryAfterEntry:(MWKHistoryEntry *)entry
{
    NSUInteger index = [self indexForEntry:entry];
    if (index == NSNotFound) {
        return nil;
    } else if (index + 1 < self.length) {
        return [self entryAtIndex:index + 1];
    } else {
        return nil;
    }
}

-(MWKHistoryEntry *)entryBeforeEntry:(MWKHistoryEntry *)entry
{
    NSUInteger index = [self indexForEntry:entry];
    if (index == NSNotFound) {
        return nil;
    } else if (index > 0) {
        return [self entryAtIndex:index - 1];
    } else {
        return nil;
    }
}

#pragma mark - update methods

-(void)addEntry:(MWKHistoryEntry *)entry
{
    MWKHistoryEntry *oldEntry = [self entryForTitle:entry.title];
    if (oldEntry) {
        // Replace the old entry and move to top
        [entries removeObject:oldEntry];
    }
    [entries insertObject:entry atIndex:0];
    entriesByTitle[entry.title] = entry;
    _dirty = YES;
}

-(void)removeEntry:(MWKHistoryEntry *)entry
{
    [entries removeObject:entry];
    [entriesByTitle removeObjectForKey:entry.title];
    _dirty = YES;
}

-(void)removeAllEntries;
{
    [entries removeAllObjects];
    [entriesByTitle removeAllObjects];
    _dirty = YES;
}

#pragma mark - data i/o methods

-(instancetype)init
{
    self = [super init];
    if (self) {
        entries = [[NSMutableArray alloc] init];
        entriesByTitle = [[NSMutableDictionary alloc] init];
    }
    return self;
}

-(instancetype)initWithDict:(NSDictionary *)dict
{
    self = [self init];
    if (self) {
        NSArray *arr = dict[@"entries"];
        if (arr) {
            entries = [[NSMutableArray alloc] init];
            for (NSDictionary *entryDict in arr) {
                MWKHistoryEntry *entry = [[MWKHistoryEntry alloc] initWithDict:entryDict];
                [entries addObject:entry];
                entriesByTitle[entry.title] = entry;
            }
        }
        _dirty = NO;
    }
    return self;
}

-(id)dataExport
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    
    for (MWKHistoryEntry *entry in entries) {
        [array addObject:[entry dataExport]];
    }

    _dirty = NO;
    return @{@"entries": [NSArray arrayWithArray:array]};
}


@end

//
//  MWKRecentSearchList.m
//  MediaWikiKit
//
//  Created by Brion on 11/18/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "MediaWikiKit.h"

@implementation MWKRecentSearchList {
    NSMutableArray *entries;
}

- (instancetype) init
{
    self = [super init];
    if (self) {
        entries = [[NSMutableArray alloc] init];
    }
    _dirty = NO;
    return self;
}

- (instancetype)initWithDict:(NSDictionary *)dict
{
    self = [self init];
    if (self) {
        for (NSDictionary *entryDict in dict[@"entries"]) {
            MWKRecentSearchEntry *entry = [[MWKRecentSearchEntry alloc] initWithDict:entryDict];
            [entries addObject:entry];
        }
    }
    _dirty = NO;
    return self;
}

-(id)dataExport
{
    NSMutableArray *dicts = [[NSMutableArray alloc] init];
    for (MWKRecentSearchEntry *entry in entries) {
        [dicts addObject:[entry dataExport]];
    }
    _dirty = NO;
    return @{@"entries": dicts};
}

-(void)addEntry:(MWKRecentSearchEntry *)entry
{
    NSUInteger oldIndex = [entries indexOfObject:entry];
    if (oldIndex != NSNotFound) {
        // Move to top!
        [entries removeObjectAtIndex:oldIndex];
    }
    [entries insertObject:entry atIndex:0];
    _dirty = YES;
    // @todo trim to max?
}

-(MWKRecentSearchEntry *)entryAtIndex:(NSUInteger)index
{
    return entries[index];
}

@end

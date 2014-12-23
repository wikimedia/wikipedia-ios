//
//  MWKSavedPageList.m
//  MediaWikiKit
//
//  Created by Brion on 11/3/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "MediaWikiKit.h"

@implementation MWKSavedPageList {
    NSMutableArray *entries;
    NSMutableDictionary *entriesByTitle;
}

-(NSUInteger)length
{
    return [entries count];
}

-(MWKSavedPageEntry *)entryAtIndex:(NSUInteger)index
{
    return entries[index];
}

-(MWKSavedPageEntry *)entryForTitle:(MWKTitle *)title
{
    MWKSavedPageEntry *entry = entriesByTitle[title];
    return entry;
}

-(BOOL)isSaved:(MWKTitle *)title
{
    MWKSavedPageEntry *entry = [self entryForTitle:title];
    return (entry != nil);
}

-(NSUInteger)indexForEntry:(MWKHistoryEntry *)entry
{
    return [entries indexOfObject:entry];
}

#pragma mark - update methods

-(void)addEntry:(MWKSavedPageEntry *)entry
{
    if ([self entryForTitle:entry.title] == nil) {
        // there can be only one
        [entries insertObject:entry atIndex:0];
        entriesByTitle[entry.title] = entry;
        _dirty = YES;
    }
}

-(void)removeEntry:(MWKSavedPageEntry *)entry
{
    [entries removeObject:entry];
    [entriesByTitle removeObjectForKey:entry.title];
    _dirty = YES;
}

-(void)removeAllEntries
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
        NSArray *array = dict[@"entries"];
        for (NSDictionary *entryDict in array) {
            MWKSavedPageEntry *entry = [[MWKSavedPageEntry alloc] initWithDict:entryDict];
            [entries addObject:entry];
            entriesByTitle[entry.title] = entry;
        }
        _dirty = NO;
    }
    return self;
}

-(id)dataExport
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    
    for (MWKSavedPageEntry *entry in entries) {
        [array addObject:[entry dataExport]];
    }
    
    _dirty = NO;
    return @{@"entries": [NSArray arrayWithArray:array]};
}


- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(__unsafe_unretained id [])stackbuf
                                    count:(NSUInteger)len
{
    return [entries countByEnumeratingWithState:state objects:stackbuf count:len];
}

@end

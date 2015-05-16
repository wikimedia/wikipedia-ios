//
//  MWKSavedPageList.m
//  MediaWikiKit
//
//  Created by Brion on 11/3/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "MediaWikiKit.h"

@interface MWKSavedPageList ()

@property (nonatomic, strong) NSMutableArray* entries;
@property (nonatomic, strong) NSMutableDictionary* entriesByTitle;
@property (readwrite, nonatomic, assign) BOOL dirty;

@end

@implementation MWKSavedPageList

- (NSUInteger)length {
    return [self.entries count];
}

- (MWKSavedPageEntry*)entryAtIndex:(NSUInteger)index {
    return self.entries[index];
}

- (MWKSavedPageEntry*)entryForTitle:(MWKTitle*)title {
    MWKSavedPageEntry* entry = self.entriesByTitle[title];
    return entry;
}

- (BOOL)isSaved:(MWKTitle*)title {
    MWKSavedPageEntry* entry = [self entryForTitle:title];
    return (entry != nil);
}

- (NSUInteger)indexForEntry:(MWKHistoryEntry*)entry {
    return [self.entries indexOfObject:entry];
}

#pragma mark - update methods

- (void)addEntry:(MWKSavedPageEntry*)entry {
    if ([self entryForTitle:entry.title] == nil) {
        // there can be only one
        [self.entries insertObject:entry atIndex:0];
        self.entriesByTitle[entry.title] = entry;
        self.dirty                       = YES;
    }
}

- (void)removeEntry:(MWKSavedPageEntry*)entry {
    [self.entries removeObject:entry];
    [self.entriesByTitle removeObjectForKey:entry.title];
    self.dirty = YES;
}

- (void)removeAllEntries {
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
        NSArray* array = dict[@"entries"];
        for (NSDictionary* entryDict in array) {
            MWKSavedPageEntry* entry = [[MWKSavedPageEntry alloc] initWithDict:entryDict];
            [self.entries addObject:entry];
            self.entriesByTitle[entry.title] = entry;
        }
        self.dirty = NO;
    }
    return self;
}

- (id)dataExport {
    NSMutableArray* array = [[NSMutableArray alloc] init];

    for (MWKSavedPageEntry* entry in self.entries) {
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

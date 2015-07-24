//
//  MWKSavedPageList.m
//  MediaWikiKit
//
//  Created by Brion on 11/3/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "MediaWikiKit.h"
#import "NSError+MWKErrors.h"

@interface MWKSavedPageList ()

@property (nonatomic, strong) NSMutableArray* entries;
@property (nonatomic, strong) NSMutableDictionary* entriesByTitle;
@property (readwrite, nonatomic, assign) BOOL dirty;

@end

@implementation MWKSavedPageList

- (NSNumber*)toggleSaveStateForTitle:(MWKTitle*)title error:(NSError* __autoreleasing*)error {
    if (!title.text.length) {
        WMFSafeAssign(error, [NSError mwk_emptyTitleError]);
        return nil;
    }
    MWKSavedPageEntry* entry = [self entryForTitle:title];
    if (!entry) {
        [self addEntry:[[MWKSavedPageEntry alloc] initWithTitle:title]];
        return @YES;
    } else {
        [self removeEntry:entry];
        return @NO;
    }
}

- (NSUInteger)length {
    return [self.entries count];
}

- (MWKSavedPageEntry*)entryAtIndex:(NSUInteger)index {
    return self.entries[index];
}

- (MWKSavedPageEntry*)entryForTitle:(MWKTitle*)title {
    if (!title) {
        return nil;
    }
    MWKSavedPageEntry* entry = self.entriesByTitle[title];
    return entry;
}

- (BOOL)isSaved:(MWKTitle*)title {
    return ([self entryForTitle:title] != nil);
}

- (NSUInteger)indexForEntry:(MWKHistoryEntry*)entry {
    return [self.entries indexOfObject:entry];
}

#pragma mark - update methods

- (void)addEntry:(MWKSavedPageEntry*)entry {
    if (entry
        && ![self entryForTitle:entry.title]
        && entry.title.text.length > 0) {
        // there can be only one
        [self.entries insertObject:entry atIndex:0];
        self.entriesByTitle[entry.title] = entry;
        self.dirty                       = YES;
    }
}

- (void)removeEntry:(MWKSavedPageEntry*)entry {
    if (entry.title.text.length == 0) {
        return;
    }
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
            @try {
                MWKSavedPageEntry* entry = [[MWKSavedPageEntry alloc] initWithDict:entryDict];
                [self.entries addObject:entry];
                self.entriesByTitle[entry.title] = entry;
            } @catch (NSException* e) {
                NSLog(@"Encountered exception while reading entry %@: %@", e, entryDict);
            }
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

//
//  MWKRecentSearchList.m
//  MediaWikiKit
//
//  Created by Brion on 11/18/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "MediaWikiKit.h"

@interface MWKRecentSearchList ()

@property (readwrite, nonatomic, assign) NSUInteger length;
@property (readwrite, nonatomic, assign) BOOL dirty;
@property (nonatomic, strong) NSMutableArray* entries;

@end

@implementation MWKRecentSearchList

- (instancetype)init {
    self = [super init];
    if (self) {
        self.entries = [[NSMutableArray alloc] init];
    }
    self.dirty = NO;
    return self;
}

- (instancetype)initWithDict:(NSDictionary*)dict {
    self = [self init];
    if (self) {
        for (NSDictionary* entryDict in dict[@"entries"]) {
            MWKRecentSearchEntry* entry = [[MWKRecentSearchEntry alloc] initWithDict:entryDict];
            [self.entries addObject:entry];
        }
    }
    self.dirty = NO;
    return self;
}

- (id)dataExport {
    NSMutableArray* dicts = [[NSMutableArray alloc] init];
    for (MWKRecentSearchEntry* entry in self.entries) {
        [dicts addObject:[entry dataExport]];
    }
    self.dirty = NO;
    return @{@"entries": dicts};
}

- (void)addEntry:(MWKRecentSearchEntry*)entry {
    NSUInteger oldIndex = [self.entries indexOfObject:entry];
    if (oldIndex != NSNotFound) {
        // Move to top!
        [self.entries removeObjectAtIndex:oldIndex];
    }
    [self.entries insertObject:entry atIndex:0];
    self.dirty = YES;
    // @todo trim to max?
}

- (MWKRecentSearchEntry*)entryAtIndex:(NSUInteger)index {
    return self.entries[index];
}

@end

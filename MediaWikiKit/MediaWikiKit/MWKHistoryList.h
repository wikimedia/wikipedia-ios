//
//  MWKHistoryList.h
//  MediaWikiKit
//
//  Created by Brion on 11/17/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "MediaWikiKit.h"

@class MWKTitle;
@class MWKHistoryEntry;

@interface MWKHistoryList : MWKDataObject <NSFastEnumeration>

@property (readonly) NSUInteger length;
@property (readwrite) BOOL dirty;

-(MWKHistoryEntry *)entryAtIndex:(NSUInteger)index;
-(MWKHistoryEntry *)entryForTitle:(MWKTitle *)title;

-(NSUInteger)indexForEntry:(MWKHistoryEntry *)entry;
-(MWKHistoryEntry *)entryAfterEntry:(MWKHistoryEntry *)entry;
-(MWKHistoryEntry *)entryBeforeEntry:(MWKHistoryEntry *)entry;

/// Update the history list with a new entry.
/// May prune out old entries.
-(void)addEntry:(MWKHistoryEntry *)entry;
-(void)removeEntry:(MWKHistoryEntry *)entry;
-(void)removeAllEntries;

-(instancetype)initWithDict:(NSDictionary *)dict;

@end

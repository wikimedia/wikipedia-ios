//
//  MWKHistoryEntry+MWKRandom.h
//  Wikipedia
//
//  Created by Brian Gerstle on 10/15/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKHistoryEntry.h"
#import "MWKRandom.h"

@interface MWKHistoryEntry (MWKRandom) <MWKRandom>

/**
 *  Workaround for generating history entries that have known discovery methods (prevent false equality negatives)
 *  and dates that are significantly distinct (prevent data loss during persistence).
 *
 *  @return A unique @c MWKHistoryEntry.
 */
+ (instancetype)randomSaveableEntry;

@end

//
//  MWKSavedPageList.h
//  MediaWikiKit
//
//  Created by Brion on 11/3/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "MWKDataObject.h"

@class MWKTitle;
@class MWKSavedPageEntry;

@interface MWKSavedPageList : MWKDataObject <NSFastEnumeration>

@property (readonly, nonatomic, assign) NSUInteger length;
@property (readonly, nonatomic, assign) BOOL dirty;

- (MWKSavedPageEntry*)entryAtIndex:(NSUInteger)index;
- (NSUInteger)indexForEntry:(MWKSavedPageEntry*)entry;

- (MWKSavedPageEntry*)entryForTitle:(MWKTitle*)title;
- (BOOL)isSaved:(MWKTitle*)title;

/**
 * Toggle the save state for `title`.
 *
 * @param title Title to toggle state for, either saving or un-saving it.
 * @param error Out-param of any error that occurred while toggling save state and saving.
 *
 * @return A boxed boolean indicating the new saved state for `title` or `nil` if an error occured.
 */
- (NSNumber*)toggleSaveStateForTitle:(MWKTitle*)title error:(NSError**)error;

/// Add a new entry to the saved page list!
- (void)addEntry:(MWKSavedPageEntry*)entry;
/// Remove one.
- (void)removeEntry:(MWKSavedPageEntry*)entry;
/// Remove all
- (void)removeAllEntries;

- (instancetype)initWithDict:(NSDictionary*)dict;

@end

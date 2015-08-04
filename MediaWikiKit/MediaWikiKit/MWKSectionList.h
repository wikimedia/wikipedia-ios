//
//  MWKSectionList.h
//  MediaWikiKit
//
//  Created by Brion on 12/11/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "MWKDataObject.h"

@class MWKSection;

@interface MWKSectionList : MWKDataObject <NSFastEnumeration>

/**
 *  Creates a section list and sets the sections to the provided array.
 *
 *  @param article  The article to load sections for
 *  @param sections The sections to load
 *
 *  @return The Section List
 */
- (instancetype)initWithArticle:(MWKArticle*)article sections:(NSArray*)sections;

/**
 *  Creates a section list and loads sections from disks
 *
 *  @param article The article to load sections for
 *
 *  @return The Section List
 */
- (instancetype)initWithArticle:(MWKArticle*)article;

@property (readonly, weak, nonatomic) MWKArticle* article;

- (NSUInteger) count;
- (MWKSection*)objectAtIndexedSubscript:(NSUInteger)idx;

/// @return The first section whose `text` is not empty, or `nil` if all sections (or the receiver) are empty.
- (MWKSection*)firstNonEmptySection;

- (void)save;

- (BOOL)isEqualToSectionList:(MWKSectionList*)sectionList;

@end

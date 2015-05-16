//
//  MWKSectionList.h
//  MediaWikiKit
//
//  Created by Brion on 12/11/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "MWKDataObject.h"

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

- (void)save;

@end

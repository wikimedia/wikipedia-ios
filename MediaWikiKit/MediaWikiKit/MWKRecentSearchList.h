//
//  MWKRecentSearchList.h
//  MediaWikiKit
//
//  Created by Brion on 11/18/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "MWKDataObject.h"

@class MWKRecentSearchEntry;

@interface MWKRecentSearchList : MWKDataObject

@property (readonly, nonatomic, assign) NSUInteger length;
@property (readonly, nonatomic, assign) BOOL dirty;

- (MWKRecentSearchEntry*)entryAtIndex:(NSUInteger)index;
- (void)addEntry:(MWKRecentSearchEntry*)entry;

- (instancetype)initWithDict:(NSDictionary*)dict;

@end

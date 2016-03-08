//
//  MWKSectionList.h
//  MediaWikiKit
//
//  Created by Brion on 12/11/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "MWKDataObject.h"

@interface MWKSectionList : MWKDataObject <NSFastEnumeration>

@property (readonly) MWKArticle *article;

- (NSUInteger)count;

- (MWKSection *)objectAtIndexedSubscript:(NSUInteger)idx;
-(void)addSection:(MWKSection *)section;

- (instancetype)initWithArticle:(MWKArticle *)article;

-(void)save;

@end

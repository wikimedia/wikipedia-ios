//
//  MWKImageList.h
//  MediaWikiKit
//
//  Created by Brion on 12/3/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "MWKSiteDataObject.h"

@class MWKImage;

@interface MWKImageList : MWKSiteDataObject <NSFastEnumeration>
@property (weak, readonly) MWKArticle *article;
@property (weak, readonly) MWKSection *section;

-(instancetype)initWithArticle:(MWKArticle *)article section:(MWKSection *)section;
-(instancetype)initWithArticle:(MWKArticle *)article section:(MWKSection *)section dict:(NSDictionary *)dict;

-(NSUInteger)count;
-(NSString *)imageURLAtIndex:(NSUInteger)index;
-(MWKImage *)objectAtIndexedSubscript:(NSUInteger)index;

-(void)addImageURL:(NSString *)imageURL;

-(BOOL)hasImageURL:(NSString *)imageURL;
-(NSString *)largestImageVariant:(NSString *)image;

@property (readonly) BOOL dirty;

-(void)save;

@end

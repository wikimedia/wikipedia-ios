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

/**
 * Return an array of known URLs for the same image that a URL has been given for,
 * ordered by pixel size (smallest to largest).
 *
 * May be an empty array if none known.
 */
-(NSArray *)imageSizeVariants:(NSString *)imageURL;

/**
 * Return the URL for the largest variant of image that actually has been saved
 * for the given image URL (may be larger or smaller than requested, or same).
 *
 * May be nil if none found.
 */
-(NSString *)largestImageVariant:(NSString *)image;

@property (readonly) BOOL dirty;

-(void)save;

@end

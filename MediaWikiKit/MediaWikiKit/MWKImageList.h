//
//  MWKImageList.h
//  MediaWikiKit
//
//  Created by Brion on 12/3/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "MWKSiteDataObject.h"

#define MWK_SECTIONID_THUMBNAIL -1


@interface MWKImageList : MWKSiteDataObject

@property (readonly) MWKTitle *title;
@property (readonly) NSUInteger length;

-(instancetype)initWithTitle:(MWKTitle *)title;
-(instancetype)initWithTitle:(MWKTitle *)title dict:(NSDictionary *)dict;

-(void)addImageURL:(NSString *)imageURL sectionId:(int)sectionId;

-(NSString *)imageURLAtIndex:(NSUInteger)index sectionId:(int)sectionId;
-(BOOL)hasImageURL:(NSString *)imageURL;
-(NSString *)largestImageVariant:(NSString *)image;

-(NSArray *)imageURLsForSectionId:(int)sectionId;
-(NSArray *)imagesBySection; // returns array of arrays indexed from section 0 until the last one that's been accesseded, may not be the last section

@property (readwrite)NSString *thumbnailURL;
@end

//
//  MWKImageList.h
//  MediaWikiKit
//
//  Created by Brion on 12/3/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "MWKSiteDataObject.h"

@interface MWKImageList : MWKSiteDataObject

@property (readonly) MWKTitle *title;
@property (readonly) NSUInteger length;

-(instancetype)initWithTitle:(MWKTitle *)title;
-(instancetype)initWithTitle:(MWKTitle *)title dict:(NSDictionary *)dict;

-(void)addImageURL:(NSString *)imageURL;

-(NSString *)imageURLAtIndex:(NSUInteger)index;
-(BOOL)hasImageURL:(NSString *)imageURL;
-(NSUInteger)indexOfImageURL:(NSString *)url;
-(NSString *)largestImageVariant:(NSString *)image;

@end

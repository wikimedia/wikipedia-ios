//
//  MWKImageMetadata.h
//  MediaWikiKit
//
//  Created by Brion on 1/16/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "MWKSiteDataObject.h"

@class MWKArticle;
@class MWKImage;

@interface MWKImageMetadata : MWKSiteDataObject

@property (readonly) MWKArticle *article;
@property (readonly) NSString *name;

// Everything as MWKImageMetadataItem objects
@property (readonly) NSDictionary *extmetadata;

// Some handy props
@property (readonly) NSString *license;          // text
@property (readonly) NSString *licenseShortName; // text?
@property (readonly) NSString *licenseUrl;       // link
@property (readonly) NSString *artist;           // HTML
@property (readonly) NSString *imageDescription; // HTML

-(instancetype)initWithArticle:(MWKArticle *)article name:(NSString *)name;
-(instancetype)initWithArticle:(MWKArticle *)article name:(NSString *)name dict:(NSDictionary *)dict;

-(void)save;
-(void)remove;

@end

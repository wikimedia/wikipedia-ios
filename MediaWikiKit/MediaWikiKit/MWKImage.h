//
//  MWKImage.h
//  MediaWikiKit
//
//  Created by Brion on 10/7/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#pragma once

#import "MWKSiteDataObject.h"

@class MWKTitle;
@class MWKArticle;

@interface MWKImage : MWKSiteDataObject

// Identifiers
@property (readonly) MWKSite *site;
@property (readonly) MWKTitle *title;

// Metadata, static
@property (readonly) NSString *sourceURL;
@property (readonly) NSString *extension;
@property (readonly) NSString *fileName;
@property (readonly) NSString *fileNameNoSizePrefix;

// Metadata, variable
@property (copy) NSDate *dateLastAccessed;
@property (copy) NSDate  *dateRetrieved;
@property (copy) NSString *mimeType;
@property (copy) NSNumber *width;
@property (copy) NSNumber *height;

-(instancetype)initWithTitle:(MWKTitle *)title sourceURL:(NSString *)url;
-(instancetype)initWithTitle:(MWKTitle *)title dict:(NSDictionary *)dict;

-(void)updateWithData:(NSData *)data mimeType:(NSString *)mimeType;
-(void)updateLastAccessed;

@end

//
//  MWKSection.h
//  MediaWikiKit
//
//  Created by Brion on 10/7/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#pragma once

#import <Foundation/Foundation.h>

#import "MWKSiteDataObject.h"

@class MWKArticle;
@class MWKImageList;

@interface MWKSection : MWKSiteDataObject

@property (readonly, strong, nonatomic) MWKTitle* title;
@property (readonly, weak, nonatomic) MWKArticle* article;

@property (readonly, copy, nonatomic) NSNumber* toclevel;      // optional
@property (readonly, copy, nonatomic) NSNumber* level;         // optional; string in JSON, but seems to be number-safe?
@property (readonly, copy, nonatomic) NSString* line;          // optional; HTML
@property (readonly, copy, nonatomic) NSString* number;        // optional; can be "1.2.3"
@property (readonly, copy, nonatomic) NSString* index;         // optional; can be "T-3" for transcluded sections
@property (readonly, strong, nonatomic) MWKTitle* fromtitle; // optional
@property (readonly, copy, nonatomic) NSString* anchor;        // optional
@property (readonly, assign, nonatomic) int sectionId;           // required; -> id
@property (readonly, assign, nonatomic) BOOL references;         // optional; marked by presence of key with empty string in JSON

@property (readonly, copy, nonatomic) NSString* text;          // may be nil
@property (readonly, strong, nonatomic) MWKImageList* images;    // ?????

- (instancetype)initWithArticle:(MWKArticle*)article dict:(NSDictionary*)dict;

- (BOOL)     isLeadSection;
- (MWKTitle*)sourceTitle;

- (void)save;

@end

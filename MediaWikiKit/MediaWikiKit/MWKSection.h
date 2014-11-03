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

@interface MWKSection : MWKSiteDataObject

@property (readonly) MWKTitle *title;
@property (readonly) MWKArticle *article;

@property (readonly) NSNumber *toclevel;      // optional
@property (readonly) NSNumber *level;         // optional; string in JSON, but seems to be number-safe?
@property (readonly) NSString *line;          // optional; HTML
@property (readonly) NSString *number;        // optional; can be "1.2.3"
@property (readonly) NSString *index;         // optional; can be "T-3" for transcluded sections
@property (readonly) MWKTitle *fromtitle; // optional
@property (readonly) NSString *anchor;        // optional
@property (readonly) int       sectionId;     // required; -> id
@property (readonly) BOOL      references;    // optional; marked by presence of key with empty string in JSON

// Should this be here?
//@property (readonly) NSString *text;          // may be nil

-(instancetype)initWithArticle:(MWKArticle *)article dict:(NSDictionary *)dict;

-(BOOL)isLeadSection;

@end

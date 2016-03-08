//
//  MWKSavedPageEntry.h
//  MediaWikiKit
//
//  Created by Brion on 11/10/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "MWKSiteDataObject.h"

@interface MWKSavedPageEntry : MWKSiteDataObject

@property (readonly) MWKTitle *title;
@property (readwrite) NSDate *date;

-(instancetype)initWithTitle:(MWKTitle *)title;
-(instancetype)initWithDict:(NSDictionary *)dict;

@end
